import os
import fileinput
import re
from collections import defaultdict

rootdir = input("Path to roles folder: ")

pattern = re.compile(r"^(?:hook\.Add|AddHook)\(\"(.+)\", \"(.+)\", function\((.*)\)", flags=re.MULTILINE)
substitution = "local function \\2(\\3)"

for subdir, dirs, files in os.walk(rootdir):
    for file in files:
        path = os.path.join(subdir, file)

        # Skip shared files because generally they don't have enough hooks to justify this
        if file == "shared.lua" or file.startswith("sh_"):
            print("Skipping " + path + ", shared files are not supported")
            continue

        hooks = {}
        didReplace = False
        skipNext = False
        lastLine = None
        isRole = False
        skipped = 0

        print("Processing " + path)
        for line in fileinput.input(path, inplace=True):
            matches = pattern.finditer(line)
            replace = False
            for match_num, match in enumerate(matches, start=1):
                replace = True
                groups = match.groups()
                hookName = groups[0]
                # These hooks need to run before or after registration and un-registration happen so don't move them to the new system
                if hookName in ["Initialize", "TTTBeginRound", "TTTPlayerRoleChanged", "TTTPrepareRound", "TTTSelectRoles", "TTTTutorialRoleText", "TTTUpdateRoleState"]:
                    replace = False
                    skipped = skipped + 1
                else:
                    if hookName not in hooks:
                        hooks[hookName] = []
                    hooks[hookName].append(groups[1])

            if line.startswith("RegisterRole(ROLE)"):
                isRole = True
                skipNext = True
            else:
                if replace:
                    didReplace = True
                    print(pattern.sub(substitution, line), end='')
                elif didReplace and (line == "end)\n" or line == "end)"):
                    didReplace = False
                    print("end")
                elif skipNext:
                    skipNext = False
                else:
                    print(line, end='')
                lastLine = line

        with open(os.path.join(subdir, file), "a") as f:
            if len(hooks) > 0:
                if len(lastLine) > 0:
                    if not lastLine.isspace():
                        f.write("\n")
                    if not lastLine.endswith("\n"):
                        f.write("\n")

                role = os.path.splitext(file)[0].removeprefix("cl_").removeprefix("sh_")
                title_role = role.title()

                f.write("------------------\n")
                f.write("-- REGISTRATION --\n")
                f.write("------------------\n\n")

                f.write("ROLE.registeredhooks = {\n")
                keys = list(hooks.keys())
                keys.sort()
                lastKey = keys[len(keys) - 1]
                for key in keys:
                    handlers = hooks[key]
                    handlers.sort()
                    if len(handlers) > 1:
                        lastHandler = handlers[len(handlers) - 1]
                        f.write("    [\"" + key + "\"] = {")
                        for handlerName in handlers:
                            f.write("        [\"" + handlerName + "\"] = " + handlerName + "")
                            if handlerName != lastHandler:
                                f.write(",")
                            f.write("\n")
                        f.write("    }")
                    else:
                        f.write("    [\"" + key + "\"] = " + handlers[0])

                    if key != lastKey:
                        f.write(",")
                    f.write("\n")
                f.write("}")
                lastLine = "!PLACEHOLDER!"
            if isRole:
                if not lastLine.endswith("\n"):
                    f.write("\n")
                if not lastLine.isspace():
                    f.write("\n")
                f.write("RegisterRole(ROLE)")

        print("\tCleaned up " + str(len(hooks)) + " hook(s) and skipped " + str(skipped))