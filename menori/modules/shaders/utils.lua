local modules = (...):match('(.*%menori.modules.shaders.)')
local menori_modules = (...):match('(.*%menori.modules.)')

local ffi = require (menori_modules .. 'libs.ffi')

local features = love.graphics.getSupported()

local function readfile(path, name)
      path = path:gsub('%.', '/')
      return love.filesystem.read(path .. name .. '.glsl')
end

local chunks = {}
local function add_shader_chunk(path, name)
      chunks[name .. '.glsl'] = readfile(path, name)
end

if love._version_major > 11 and ffi then
      add_shader_chunk(modules .. 'chunks.', 'skinning_vertex_base')
      add_shader_chunk(modules .. 'chunks.', 'skinning_vertex')
else
      add_shader_chunk(modules .. 'chunks.love11.', 'skinning_vertex_base')
      add_shader_chunk(modules .. 'chunks.love11.', 'skinning_vertex')
end

add_shader_chunk(modules .. 'chunks.', 'normal')
add_shader_chunk(modules .. 'chunks.', 'billboard_base')
add_shader_chunk(modules .. 'chunks.', 'billboard')
add_shader_chunk(modules .. 'chunks.', 'inverse')
add_shader_chunk(modules .. 'chunks.', 'transpose')

local cache = {}

local function include_chunks(code)
      local lines = {}
      for line in string.gmatch(code .. "\n", "(.-)\n") do
            local temp = line:gsub("^[ \t]*#menori_include <(.-)>", function (name)
                  assert(chunks[name] ~= nil, name)
                  return chunks[name]
            end)
            table.insert(lines, temp)
      end
      return table.concat(lines, '\n')
end

local function load_shader_file(name, shaderpath, opt)
      local code = readfile(modules, shaderpath)

      if opt and opt.definitions then
            local t = {}
            for _, v in ipairs(opt.definitions) do
                  table.insert(t, string.format('#define %s\n', v))
            end
            if #t > 0 then
                  local s = table.concat(t) .. '\n'
                  code = s .. code
            end
      end

      if features['glsl3'] then
            code = '#pragma language glsl3\n' .. code
      end

      cache[name] = include_chunks(code)
end

local USE_SKINNING = {
      definitions = {"USE_SKINNING"}
}
local BILLBOARD_ROTATE = {
      definitions = {"BILLBOARD_ROTATE"}
}

load_shader_file('default_mesh_vert', 'default_mesh_vert')
load_shader_file('default_mesh_frag', 'default_mesh_frag')

load_shader_file('default_mesh_skinning_vert', 'default_mesh_vert', USE_SKINNING)
load_shader_file('default_mesh_skinning_frag', 'default_mesh_frag', USE_SKINNING)

load_shader_file('deferred_mesh_frag', 'deferred_mesh_frag')

load_shader_file('deferred_mesh_skinning_vert', 'default_mesh_vert', USE_SKINNING)
load_shader_file('deferred_mesh_skinning_frag', 'default_mesh_frag', USE_SKINNING)

load_shader_file('instanced_mesh_vert', 'instanced_mesh_vert')

load_shader_file('instanced_mesh_billboard_vert', 'instanced_mesh_vert', BILLBOARD_ROTATE)
load_shader_file('instanced_mesh_billboard_frag', 'default_mesh_frag', BILLBOARD_ROTATE)

load_shader_file('outline_mesh_vert', 'outline_mesh_vert')
load_shader_file('outline_mesh_frag', 'outline_mesh_frag')

local shaders = {
      default_mesh = love.graphics.newShader(cache['default_mesh_vert'], cache['default_mesh_frag']),
      default_mesh_skinning = love.graphics.newShader(cache['default_mesh_skinning_vert'], cache['default_mesh_skinning_frag']),
      deferred_mesh = love.graphics.newShader(cache['default_mesh_vert'], cache['deferred_mesh_frag']),
      deferred_mesh_skinning = love.graphics.newShader(cache['deferred_mesh_skinning_vert'], cache['deferred_mesh_skinning_frag']),

      instanced_mesh = love.graphics.newShader(cache['instanced_mesh_vert'], cache['default_mesh_frag']),
      instanced_mesh_billboard = love.graphics.newShader(cache['instanced_mesh_billboard_vert'], cache['default_mesh_frag']),

      outline_mesh = love.graphics.newShader(cache['outline_mesh_vert'], cache['outline_mesh_frag']),
}

return {
      cache = cache,
      add_shader_chunk = add_shader_chunk,
      load_shader_file = load_shader_file,
      shaders = shaders,
}