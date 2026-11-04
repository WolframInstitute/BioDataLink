"""Read a bounded matrix projection of documented AnnData/HDF5 encodings.

This is a local file reader, not an AnnData object round trip. It does not load
unselected matrices, execute serialized objects, or follow HDF5 external links.
The command protocol is two paths: a JSON request and a bounded JSON response.
"""
import json
import os
import sys


class ReadError(Exception):
    def __init__(self, tag, message):
        self.tag, self.message = tag, message


def fail(tag, message):
    raise ReadError(tag, message)


def text(value):
    return value.decode("utf-8") if isinstance(value, bytes) else str(value)


def encoding(node):
    return (text(node.attrs.get("encoding-type", "")),
            text(node.attrs.get("encoding-version", "")))


def child(group, key):
    if not isinstance(group, h5py.Group):
        fail("InvalidAnnData", "A required H5AD group has the wrong storage type.")
    if key not in group:
        fail("InvalidAnnData", "A required H5AD element is missing.")
    if not isinstance(group.get(key, getlink=True), h5py.HardLink):
        fail("UnsupportedHDF5Link", "Selected H5AD elements must not use soft or external links.")
    node = group[key]
    if isinstance(node, h5py.Dataset) and (node.is_virtual or node.external):
        fail("UnsupportedHDF5Link", "Virtual and externally stored HDF5 datasets are not supported.")
    return node


def select_indices(selection, length):
    if selection is None:
        return np.arange(length, dtype=np.int64)
    if (not isinstance(selection, list) or not selection
            or any(type(x) is not int or not 1 <= x <= length for x in selection)
            or len(set(selection)) != len(selection)):
        fail("InvalidSelection", "Axis selections must be nonempty, unique, valid one-based positions.")
    return np.asarray(selection, dtype=np.int64) - 1


def take_vector(dataset, indices):
    if not isinstance(dataset, h5py.Dataset) or dataset.ndim != 1:
        fail("UnsupportedAnnotation", "Metadata values must use supported one-dimensional encodings.")
    if not len(indices):
        return np.empty(0, dtype=dataset.dtype)
    order = np.argsort(indices)
    values = dataset[indices[order]]
    return values[np.argsort(order)]


def scalar(value):
    if isinstance(value, np.generic):
        value = value.item()
    if isinstance(value, bytes):
        return value.decode("utf-8")
    if value is None or isinstance(value, (str, bool, int)):
        return value
    if isinstance(value, float):
        if np.isnan(value):
            return None
        if np.isfinite(value):
            return value
    fail("UnsupportedAnnotation", "Metadata contains an unsupported scalar or infinite value.")


def read_categorical(node, indices):
    codes = take_vector(child(node, "codes"), indices)
    categories = child(node, "categories")
    if not isinstance(categories, h5py.Dataset) or categories.ndim != 1:
        fail("UnsupportedAnnotation", "Categorical labels must be a one-dimensional dataset.")
    if codes.dtype.kind not in "iu" or np.any(codes < -1) or np.any(codes >= len(categories)):
        fail("InvalidAnnData", "Categorical codes lie outside their category table.")
    ordered = node.attrs.get("ordered")
    if not isinstance(ordered, (bool, np.bool_)):
        fail("InvalidAnnData", "A categorical ordered flag must be Boolean.")
    used = np.unique(codes[codes >= 0]).astype(np.int64)
    labels = dict(zip(used.tolist(), read_column(categories, used)))
    schema = {"Ordered": bool(ordered), "CategoryCount": len(categories),
              "SelectedCategories": [{"SourceIndex": code + 1, "Value": value}
                                     for code, value in labels.items()]}
    return [None if code == -1 else labels[int(code)] for code in codes], schema


def read_column(node, indices):
    kind, version = encoding(node)
    if (kind, version) in {("array", "0.2.0"), ("string-array", "0.2.0")}:
        return [scalar(x) for x in take_vector(node, indices)]
    if (kind, version) == ("categorical", "0.2.0"):
        return read_categorical(node, indices)[0]
    if kind in {"nullable-integer", "nullable-boolean", "nullable-string-array"} and version == "0.1.0":
        value_node = child(node, "values")
        expected = {"nullable-integer": "iu", "nullable-boolean": "b", "nullable-string-array": "OSUT"}[kind]
        if not isinstance(value_node, h5py.Dataset) or value_node.dtype.kind not in expected:
            fail("InvalidAnnData", "Nullable metadata values do not match their declared encoding.")
        values = take_vector(value_node, indices)
        mask = take_vector(child(node, "mask"), indices)
        if len(values) != len(mask) or mask.dtype.kind != "b":
            fail("InvalidAnnData", "A nullable metadata mask is malformed.")
        return [None if missing else scalar(value) for value, missing in zip(values, mask)]
    fail("UnsupportedAnnotation", "A metadata column has an unsupported H5AD encoding or version.")


def column_length(node):
    if isinstance(node, h5py.Dataset) and node.ndim == 1:
        return len(node)
    kind, version = encoding(node)
    if kind == "categorical" and version == "0.2.0":
        return column_length(child(node, "codes"))
    if kind in {"nullable-integer", "nullable-boolean", "nullable-string-array"} and version == "0.1.0":
        size = column_length(child(node, "values"))
        if size != column_length(child(node, "mask")):
            fail("InvalidAnnData", "A nullable metadata mask has the wrong length.")
        return size
    fail("UnsupportedAnnotation", "Metadata must use a supported one-dimensional column encoding.")


def frame_index(frame):
    if not isinstance(frame, h5py.Group) or encoding(frame) != ("dataframe", "0.2.0"):
        fail("UnsupportedAnnotation", "Axis metadata must use dataframe encoding 0.2.0.")
    key = frame.attrs.get("_index")
    if not isinstance(key, (str, bytes)):
        fail("InvalidAnnData", "The axis dataframe has no index declaration.")
    index = child(frame, text(key))
    column_length(index)
    return index


def metadata(frame, selection, budget):
    ids = read_column(frame_index(frame), selection)
    if any(not isinstance(x, str) for x in ids):
        fail("UnsupportedAnnotation", "Axis labels must be strings; duplicate labels are preserved.")
    raw_columns = frame.attrs.get("column-order", [])
    if any(not isinstance(x, (str, bytes)) for x in raw_columns):
        fail("UnsupportedAnnotation", "Metadata column names must be strings.")
    columns = [text(x) for x in raw_columns]
    if len(set(columns)) != len(columns):
        fail("InvalidAnnData", "Metadata column names must be unique.")
    rows, used = [], 0
    for name, index in zip(ids, selection):
        row = {"ID": name, "SourceIndex": int(index) + 1, "Annotations": {}}
        used += len(json.dumps(row, ensure_ascii=False).encode("utf-8"))
        if used > budget:
            fail("TransferTooLarge", "The selected metadata exceeds MaxTransferBytes.")
        rows.append(row)
    schemas = {}
    axis_length = column_length(frame_index(frame))
    for column in columns:
        if used > budget:
            fail("TransferTooLarge", "The selected metadata exceeds MaxTransferBytes.")
        node = child(frame, column)
        if column_length(node) != axis_length:
            fail("InvalidAnnData", "A metadata column has the wrong axis length.")
        kind, version = encoding(node)
        schemas[column] = {"Encoding": kind, "Version": version}
        if (kind, version) == ("categorical", "0.2.0"):
            values, category_schema = read_categorical(node, selection)
            schemas[column].update(category_schema)
        else:
            values = read_column(node, selection)
        for row, value in zip(rows, values):
            used += len(column.encode("utf-8")) + len(json.dumps(value, ensure_ascii=False).encode("utf-8")) + 6
            if used > budget:
                fail("TransferTooLarge", "The selected metadata exceeds MaxTransferBytes.")
            row["Annotations"][column] = value
    return rows, schemas


def matrix_shape(node):
    kind, version = encoding(node)
    if isinstance(node, h5py.Dataset) and (kind, version) == ("array", "0.2.0"):
        shape = node.shape
    elif isinstance(node, h5py.Group) and kind in {"csr_matrix", "csc_matrix"} and version == "0.1.0":
        shape = node.attrs.get("shape", ())
    else:
        fail("UnsupportedMatrixEncoding", "Supported matrices are dense array 0.2.0 and CSR/CSC 0.1.0.")
    if len(shape) != 2 or any(not isinstance(x, (int, np.integer)) or isinstance(x, (bool, np.bool_))
                              or x <= 0 for x in shape):
        fail("InvalidAnnData", "The selected matrix must have two nonempty axes.")
    return tuple(int(x) for x in shape)


def number_values(values):
    if values.dtype.kind not in "iuf" or values.dtype.itemsize > 8:
        fail("UnsupportedMatrixEncoding", "The selected matrix must contain real numeric values of at most 64 bits.")
    if not np.all(np.isfinite(values)):
        fail("MissingMeasurement", "Selected matrix values contain NaN or infinity; they cannot be represented as numeric zeros.")


def entries(node, cells, genes, shape):
    """Yield selected COO triples in bounded blocks, retaining integer precision."""
    kind, _ = encoding(node)
    if kind == "array":
        for row, source_row in enumerate(cells):
            for start in range(0, len(genes), 8192):
                # h5py permits a sorted fancy index on one axis only.
                selected = genes[start:start + 8192]
                part_order = np.argsort(selected)
                values = node[int(source_row), selected[part_order]][np.argsort(part_order)]
                number_values(values)
                nonzero = np.flatnonzero(values)
                yield [[row + 1, start + int(col) + 1, scalar(values[col])] for col in nonzero]
        return
    pointers, indices, values = (child(node, key) for key in ("indptr", "indices", "data"))
    major, minor = (cells, genes) if kind == "csr_matrix" else (genes, cells)
    major_count, minor_count = shape if kind == "csr_matrix" else shape[::-1]
    if (any(not isinstance(x, h5py.Dataset) or x.ndim != 1 for x in (pointers, indices, values))
            or pointers.dtype.kind not in "iu" or indices.dtype.kind not in "iu"
            or len(pointers) != major_count + 1 or len(indices) != len(values)
            or int(pointers[0]) != 0 or int(pointers[-1]) != len(values)):
        fail("InvalidAnnData", "The sparse matrix storage is malformed.")
    minor_map = {int(source): selected + 1 for selected, source in enumerate(minor)}
    for target_major, source_major in enumerate(major):
        begin, end = (int(x) for x in pointers[int(source_major):int(source_major) + 2])
        if not 0 <= begin <= end <= len(values):
            fail("InvalidAnnData", "Sparse matrix row or column pointers are malformed.")
        seen = set()
        for start in range(begin, end, 8192):
            stop = min(start + 8192, end)
            column_ids = indices[start:stop]
            if np.any(column_ids >= minor_count) or np.any(column_ids < 0):
                fail("InvalidAnnData", "Sparse matrix indices are outside the source shape.")
            chosen = [(offset, minor_map[int(column)]) for offset, column in enumerate(column_ids)
                      if int(column) in minor_map]
            if not chosen:
                continue
            offsets = np.asarray([x[0] for x in chosen], dtype=np.int64)
            selected_values = values[start:stop][offsets]
            number_values(selected_values)
            block = []
            for (_, target_minor), value in zip(chosen, selected_values):
                if target_minor in seen:
                    fail("DuplicateCoordinates", "The selected sparse matrix contains duplicate coordinates.")
                seen.add(target_minor)
                if value != 0:
                    coordinates = [target_major + 1, target_minor] if kind == "csr_matrix" else [target_minor, target_major + 1]
                    block.append(coordinates + [scalar(value)])
            yield block


class BoundedWriter:
    def __init__(self, file, limit):
        self.file, self.limit, self.written = file, limit, 0

    def write(self, value):
        data = value.encode("utf-8")
        self.written += len(data)
        if self.written > self.limit:
            fail("TransferTooLarge", "The selected result exceeds MaxTransferBytes.")
        self.file.write(data)


def read_projection(request, output):
    source = request["SourceFile"]
    before = os.stat(source)
    if request["MaxFileBytes"] is not None and before.st_size > request["MaxFileBytes"]:
        fail("FileTooLarge", "The local file exceeds MaxFileBytes.")
    with h5py.File(source, "r") as file:
        if encoding(file) != ("anndata", "0.1.0"):
            fail("UnsupportedAnnData", "The file must use AnnData encoding 0.1.0.")
        obs, main_var = child(file, "obs"), child(file, "var")
        layer = request["Layer"]
        if layer == "X":
            matrix, var = child(file, "X"), main_var
        elif layer[0] == "Layers":
            layers = child(file, "layers")
            if encoding(layers) != ("dict", "0.1.0"):
                fail("UnsupportedAnnData", "The layers mapping must use dict encoding 0.1.0.")
            matrix, var = child(layers, layer[1]), main_var
        else:
            raw = child(file, "raw")
            if encoding(raw) != ("raw", "0.1.0"):
                fail("UnsupportedAnnData", "The raw group must use raw encoding 0.1.0.")
            matrix, var = child(raw, "X"), child(raw, "var")
        shape = matrix_shape(matrix)
        value_dataset = matrix if isinstance(matrix, h5py.Dataset) else child(matrix, "data")
        if not isinstance(value_dataset, h5py.Dataset):
            fail("InvalidAnnData", "The selected matrix values must be stored in a dataset.")
        value_type = value_dataset.dtype
        number_values(np.empty(0, dtype=value_type))
        if shape != (column_length(frame_index(obs)), column_length(frame_index(var))):
            fail("InvalidAnnData", "Matrix dimensions do not match the selected axis metadata.")
        # Check sizes before allocating an All selection or reading any matrix values.
        selected_shape = [shape[i] if request[key] is None else len(request[key])
                          for i, key in enumerate(("Cells", "Genes"))]
        if selected_shape[0] * selected_shape[1] > request["MaxSelectedElements"]:
            fail("SelectionTooLarge", "The selected matrix shape exceeds MaxSelectedElements.")
        if sum(selected_shape) > request["MaxTransferBytes"] // 16:
            fail("TransferTooLarge", "The axis metadata cannot fit within MaxTransferBytes.")
        cells = select_indices(request["Cells"], shape[0])
        genes = select_indices(request["Genes"], shape[1])
        cell_metadata, cell_schema = metadata(obs, cells, request["MaxTransferBytes"])
        gene_metadata, gene_schema = metadata(var, genes, request["MaxTransferBytes"])
        omitted = []
        for key in file.keys():
            if key in {"obs", "var", "X"}:
                continue
            if key == "layers":
                group = child(file, key)
                omitted.extend("layers/" + name for name in group.keys()
                               if layer != ["Layers", name])
            elif key == "raw" and layer == ["Raw", "X"]:
                omitted.extend("raw/" + name for name in child(file, key).keys() if name not in {"X", "var"})
            else:
                omitted.append(key)
        if layer != "X":
            omitted.append("X")
        if layer == ["Raw", "X"]:
            omitted.append("var")
        payload = {"Status": "OK", "Format": "AnnData", "Shape": selected_shape, "MatrixValueType": value_type.name,
                   "SourceShape": list(shape), "SourceLayer": layer,
                   "SelectedCells": (cells + 1).tolist(), "SelectedGenes": (genes + 1).tolist(),
                   "CellMetadata": cell_metadata, "GeneMetadata": gene_metadata,
                   "CellMetadataEncoding": cell_schema, "GeneMetadataEncoding": gene_schema,
                   "OmittedStructures": sorted(omitted),
                   "BackendVersion": {"Python": sys.version.split()[0], "h5py": h5py.__version__, "NumPy": np.__version__},
                   "SourceFileBytes": before.st_size,
                   "SourceFileModifiedUnixNanoseconds": before.st_mtime_ns}
        writer = BoundedWriter(output, request["MaxTransferBytes"])
        writer.write(json.dumps(payload, ensure_ascii=False, allow_nan=False)[:-1] + ',"Entries":[')
        first = True
        for block in entries(matrix, cells, genes, shape):
            if block:
                writer.write(("" if first else ",") + json.dumps(block, separators=(",", ":"), allow_nan=False)[1:-1])
                first = False
        writer.write("]}")
    after = os.stat(source)
    if (before.st_size, before.st_mtime_ns, before.st_ino) != (after.st_size, after.st_mtime_ns, after.st_ino):
        fail("SourceFileChanged", "The source file changed while its projection was being read.")


def main():
    global h5py, np
    request_path, result_path = sys.argv[1:]
    try:
        import h5py
        import numpy as np
    except ImportError:
        error = {"Status": "Error", "Tag": "MissingPythonDependency",
                 "Message": "The selected Python interpreter requires h5py and NumPy."}
    else:
        try:
            with open(request_path, encoding="utf-8") as file:
                request = json.load(file)
            with open(result_path, "wb") as output:
                read_projection(request, output)
            return
        except ReadError as exc:
            error = {"Status": "Error", "Tag": exc.tag, "Message": exc.message}
        except (OSError, ValueError, TypeError, KeyError, UnicodeError, OverflowError):
            error = {"Status": "Error", "Tag": "InvalidAnnData",
                     "Message": "The H5AD file could not be read using the supported encoding contract."}
    with open(result_path, "w", encoding="utf-8") as output:
        json.dump(error, output)


if __name__ == "__main__":
    main()
