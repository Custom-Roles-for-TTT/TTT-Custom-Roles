package = "luacheck"
version = "dev-1"
source = {
   url = "git+https://github.com/mpeterv/luacheck.git"
}
description = {
   summary = "A static analyzer and a linter for Lua",
   detailed = [[
Luacheck is a command-line tool for linting and static analysis of Lua code.
It is able to spot usage of undefined global variables, unused local variables and
a few other typical problems within Lua programs.
]],
   homepage = "https://github.com/mpeterv/luacheck",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1, < 5.4",
   "argparse >= 0.6.0",
   "luafilesystem >= 1.6.3"
}
build = {
   type = "builtin",
   modules = {
      luacheck = "gluacheck/src/luacheck/init.lua",
      ["luacheck.builtin_standards"] = "gluacheck/src/luacheck/builtin_standards/init.lua",
      ["luacheck.builtin_standards.love"] = "gluacheck/src/luacheck/builtin_standards/love.lua",
      ["luacheck.builtin_standards.ngx"] = "gluacheck/src/luacheck/builtin_standards/ngx.lua",
      ["luacheck.cache"] = "gluacheck/src/luacheck/cache.lua",
      ["luacheck.check"] = "gluacheck/src/luacheck/check.lua",
      ["luacheck.check_state"] = "gluacheck/src/luacheck/check_state.lua",
      ["luacheck.config"] = "gluacheck/src/luacheck/config.lua",
      ["luacheck.core_utils"] = "gluacheck/src/luacheck/core_utils.lua",
      ["luacheck.decoder"] = "gluacheck/src/luacheck/decoder.lua",
      ["luacheck.expand_rockspec"] = "gluacheck/src/luacheck/expand_rockspec.lua",
      ["luacheck.filter"] = "gluacheck/src/luacheck/filter.lua",
      ["luacheck.format"] = "gluacheck/src/luacheck/format.lua",
      ["luacheck.fs"] = "gluacheck/src/luacheck/fs.lua",
      ["luacheck.globbing"] = "gluacheck/src/luacheck/globbing.lua",
      ["luacheck.lexer"] = "gluacheck/src/luacheck/lexer.lua",
      ["luacheck.main"] = "gluacheck/src/luacheck/main.lua",
      ["luacheck.multithreading"] = "gluacheck/src/luacheck/multithreading.lua",
      ["luacheck.options"] = "gluacheck/src/luacheck/options.lua",
      ["luacheck.parser"] = "gluacheck/src/luacheck/parser.lua",
      ["luacheck.profiler"] = "gluacheck/src/luacheck/profiler.lua",
      ["luacheck.runner"] = "gluacheck/src/luacheck/runner.lua",
      ["luacheck.serializer"] = "gluacheck/src/luacheck/serializer.lua",
      ["luacheck.stages"] = "gluacheck/src/luacheck/stages/init.lua",
      ["luacheck.stages.detect_bad_whitespace"] = "gluacheck/src/luacheck/stages/detect_bad_whitespace.lua",
      ["luacheck.stages.detect_cyclomatic_complexity"] = "gluacheck/src/luacheck/stages/detect_cyclomatic_complexity.lua",
      ["luacheck.stages.detect_empty_blocks"] = "gluacheck/src/luacheck/stages/detect_empty_blocks.lua",
      ["luacheck.stages.detect_empty_statements"] = "gluacheck/src/luacheck/stages/detect_empty_statements.lua",
      ["luacheck.stages.detect_globals"] = "gluacheck/src/luacheck/stages/detect_globals.lua",
      ["luacheck.stages.detect_reversed_fornum_loops"] = "gluacheck/src/luacheck/stages/detect_reversed_fornum_loops.lua",
      ["luacheck.stages.detect_unbalanced_assignments"] = "gluacheck/src/luacheck/stages/detect_unbalanced_assignments.lua",
      ["luacheck.stages.detect_uninit_accesses"] = "gluacheck/src/luacheck/stages/detect_uninit_accesses.lua",
      ["luacheck.stages.detect_unreachable_code"] = "gluacheck/src/luacheck/stages/detect_unreachable_code.lua",
      ["luacheck.stages.detect_unused_fields"] = "gluacheck/src/luacheck/stages/detect_unused_fields.lua",
      ["luacheck.stages.detect_unused_locals"] = "gluacheck/src/luacheck/stages/detect_unused_locals.lua",
      ["luacheck.stages.linearize"] = "gluacheck/src/luacheck/stages/linearize.lua",
      ["luacheck.stages.name_functions"] = "gluacheck/src/luacheck/stages/name_functions.lua",
      ["luacheck.stages.parse"] = "gluacheck/src/luacheck/stages/parse.lua",
      ["luacheck.stages.parse_inline_options"] = "gluacheck/src/luacheck/stages/parse_inline_options.lua",
      ["luacheck.stages.resolve_locals"] = "gluacheck/src/luacheck/stages/resolve_locals.lua",
      ["luacheck.stages.unwrap_parens"] = "gluacheck/src/luacheck/stages/unwrap_parens.lua",
      ["luacheck.standards"] = "gluacheck/src/luacheck/standards.lua",
      ["luacheck.unicode"] = "gluacheck/src/luacheck/unicode.lua",
      ["luacheck.unicode_printability_boundaries"] = "gluacheck/src/luacheck/unicode_printability_boundaries.lua",
      ["luacheck.utils"] = "gluacheck/src/luacheck/utils.lua",
      ["luacheck.vendor.sha1"] = "gluacheck/src/luacheck/vendor/sha1/init.lua",
      ["luacheck.vendor.sha1.bit_ops"] = "gluacheck/src/luacheck/vendor/sha1/bit_ops.lua",
      ["luacheck.vendor.sha1.bit32_ops"] = "gluacheck/src/luacheck/vendor/sha1/bit32_ops.lua",
      ["luacheck.vendor.sha1.common"] = "gluacheck/src/luacheck/vendor/sha1/common.lua",
      ["luacheck.vendor.sha1.lua53_ops"] = "gluacheck/src/luacheck/vendor/sha1/lua53_ops.lua",
      ["luacheck.vendor.sha1.pure_lua_ops"] = "gluacheck/src/luacheck/vendor/sha1/pure_lua_ops.lua",
      ["luacheck.version"] = "gluacheck/src/luacheck/version.lua"
   },
   install = {
      bin = {
         luacheck = "gluacheck/bin/luacheck.lua"
      }
   }
}
