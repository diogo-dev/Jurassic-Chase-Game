local path = {}

path.tileSize = 64
path.width = 16
path.height = 12

-- 0 = livre, 1 = bloqueado
path.grid = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0,
    0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1,
    0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0,
    1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0,
    1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0,
    1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0,
    1, 0, 1, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0,
    1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0,
    0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0,
    0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0
}

-- converte (x, y) do mundo → coordenadas da grade
local function pixelToTile(x, y)
    local col = math.floor(x / path.tileSize) + 1
    local row = math.floor(y / path.tileSize) + 1
    return col, row
end

-- converte (col, row) → índice da tabela 1D
local function getIndex(col, row)
    if col < 1 or col > path.width or row < 1 or row > path.height then
        return nil
    end
    return (row - 1) * path.width + col
end

-- verifica se o tile é livre (0)
function path.isFree(x, y)
    local col, row = pixelToTile(x, y)
    local index = getIndex(col, row)
    if not index then return false end
    return path.grid[index] == 0
end

return path
