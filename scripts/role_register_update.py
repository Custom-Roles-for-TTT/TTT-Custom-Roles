import os
import fileinput
import re
from collections import defaultdict

rootdir = input("Path to roles folder: ")

pattern = re.compile(r"(?:hook\.Add|AddHook)\(\"(.+)\", \"(.+)\", function\((.*)\)", flags=re.MULTILINE)
named_pattern = re.compile(r"(?:hook\.Add|AddHook)\(\"(.+)\", \"(.+)\", (?!function)(.*)\)", flags=re.MULTILINE)
space_pattern = re.compile(r"\s*")
substitution = "local function \\2(\\3)"

def file_output(fileHandle, line, newline = False):
    if fileHandle != None:
        fileHandle.write(line)
        if newline:
            fileHandle.write("\n")
    elif newline:
        print(line)
    else:
        print(line, end='')

def write_hooks(file, isRole, hooks, lastLine, fileHandle, lineSpaces = ""):
    if len(hooks) == 0:
        return lastLine

    if len(lastLine) > 0:
        if not lastLine.isspace():
            file_output(fileHandle, "\n")
        if not lastLine.endswith("\n"):
            file_output(fileHandle, "\n")

    role = os.path.splitext(file)[0].removeprefix("cl_").removeprefix("sh_").upper()

    file_output(fileHandle, lineSpaces + "------------------", True)
    file_output(fileHandle, lineSpaces + "-- REGISTRATION --", True)
    file_output(fileHandle, lineSpaces + "------------------\n", True)

    if isRole:
        file_output(fileHandle, lineSpaces + "ROLE.registeredhooks = {", True)
    else:
        file_output(fileHandle, lineSpaces + "ROLE_REGISTERED_HOOKS[ROLE_" + role + "] = {", True)
    keys = list(hooks.keys())
    keys.sort()
    lastKey = keys[len(keys) - 1]
    for key in keys:
        handlers = list(hooks[key].keys())
        handlers.sort()
        if len(handlers) > 1:
            lastHandler = handlers[len(handlers) - 1]
            file_output(fileHandle, lineSpaces + "    [\"" + key + "\"] = {")
            for handlerName in handlers:
                fnName = handlerName
                if hooks[key][handlerName] != None:
                    fnName = hooks[key][handlerName]
                file_output(fileHandle, lineSpaces + "        [\"" + handlerName + "\"] = " + fnName + "")
                if handlerName != lastHandler:
                    file_output(fileHandle, ",")
                file_output(fileHandle, "\n")
            file_output(fileHandle, lineSpaces + "    }")
        else:
            handlerName = handlers[0]
            fnName = handlerName
            if hooks[key][handlerName] != None:
                fnName = hooks[key][handlerName]
            file_output(fileHandle, lineSpaces + "    [\"" + key + "\"] = " + fnName)

        if key != lastKey:
            file_output(fileHandle, ",")
        file_output(fileHandle, "\n")
    file_output(fileHandle, lineSpaces + "}")
    return "!PLACEHOLDER!"

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
        updated = 0
        lineSpaces = ""
        inScope = False
        scopeSpaces = None

        # Check if this file registers a role because we handle the hooks differently
        with open(os.path.join(subdir, file)) as f:
            if "RegisterRole(ROLE)" in f.read():
                isRole = True

        print("Processing " + path)
        for line in fileinput.input(path, inplace=True):
            namedMatch = False
            matches = []
            if pattern.search(line) != None:
                matches = pattern.finditer(line)
            elif named_pattern.search(line) != None:
                namedMatch = True
                matches = named_pattern.finditer(line)

            replace = False
            for match_num, match in enumerate(matches, start=1):
                replace = not namedMatch
                groups = match.groups()
                hookName = groups[0]
                hookId = groups[1]
                # These hooks need to run before or after registration and un-registration happen so don't move them to the new system
                if hookName in ["Initialize", "TTTBeginRound", "TTTPlayerRoleChanged", "TTTPrepareRound", "TTTSelectRoles", "TTTTutorialRoleText", "TTTUpdateRoleState"]:
                    replace = False
                    namedMatch = False
                    skipped += 1
                else:
                    if hookName not in hooks:
                        hooks[hookName] = {}
                    if namedMatch:
                        hooks[hookName][hookId] = groups[2]
                    else:
                        hooks[hookName][hookId] = None

            # If this is the registration line we want to skip it and the next (assumingly blank) line
            if line.startswith("RegisterRole(ROLE)"):
                skipNext = True
            else:
                # If we're in a SERVER or CLIENT scope
                if inScope:
                    # Save the first line within it's spaces so we know how
                    # many spaces to add to the hook mapping in this scope
                    if scopeSpaces == None:
                        space_match = space_pattern.match(line)
                        if space_match:
                            scopeSpaces = space_match.group()
                    # And we're ending the scope, print out the hooks that belong to it
                    if line == "end\n" or line == "end":
                        hooksToAdd = len(hooks)
                        if hooksToAdd > 0:
                            updated += hooksToAdd
                            lastLine = write_hooks(file, isRole, hooks, lastLine, None, scopeSpaces)
                            print("")
                            hooks = {}
                            scopeSpaces = None
                            inScope = False

                if replace:
                    didReplace = True
                    print(pattern.sub(substitution, line), end='')

                    # If this hook definition starts with spaces, save the amount so we know
                    # how much to indent the end line
                    space_match = space_pattern.match(line)
                    if space_match:
                        lineSpaces = space_match.group()
                # If we're ending a hook definition, remove the ending paren
                elif didReplace and (line == lineSpaces + "end)\n" or line == lineSpaces + "end)"):
                    didReplace = False
                    print(lineSpaces + "end")
                    lineSpaces = ""
                elif skipNext or namedMatch:
                    skipNext = False
                    if line.isspace():
                        print(line, end='')
                    else:
                        line = "!PLACEHOLDER!\n"
                else:
                    if line.startswith("if SERVER then") or line.startswith("if CLIENT then"):
                        inScope = True
                    print(line, end='')
                lastLine = line

        with open(os.path.join(subdir, file), "a") as f:
            updated += len(hooks)
            lastLine = write_hooks(file, isRole, hooks, lastLine, f)
            if isRole:
                if not lastLine.endswith("\n"):
                    f.write("\n")
                if not lastLine.isspace():
                    f.write("\n")
                f.write("RegisterRole(ROLE)")

        print("\tCleaned up " + str(updated) + " hook(s) and skipped " + str(skipped))