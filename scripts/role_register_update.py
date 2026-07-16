import os
import fileinput
import re
from collections import defaultdict

rootdir = input("Path to roles folder: ")

pattern = re.compile(r"(?:hook\.Add|AddHook)\(\"(.+)\", \"(.+)\", function\((.*)\)", flags=re.MULTILINE)
named_pattern = re.compile(r"(?:hook\.Add|AddHook)\(\"(.+)\", \"(.+)\", (?!function)(.*)\)", flags=re.MULTILINE)
space_pattern = re.compile(r" *")
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

def write_hooks(file, isRole, hooks, lastLine, fileHandle, hasScope, lineSpaces = ""):
    # If we didn't just write a blank line, we might want to add a spacer
    if len(lastLine) > 0:
        if not lastLine.isspace():
            file_output(fileHandle, "\n")
        if not lastLine.endswith("\n"):
            file_output(fileHandle, "\n")

    role = os.path.splitext(file)[0].removeprefix("cl_").removeprefix("sh_").upper()
    keys = list(hooks.keys())
    keys.sort()
    keyLen = len(keys)
    lastKey = None
    prefix = "    "

    file_output(fileHandle, lineSpaces + "------------------", True)
    file_output(fileHandle, lineSpaces + "-- REGISTRATION --", True)
    file_output(fileHandle, lineSpaces + "------------------\n", True)

    # Set up the table accessor depending on the current state
    if hasScope:
        if isRole:
            prefix = "ROLE.registeredhooks"
        else:
            prefix = "ROLE_REGISTERED_HOOKS[ROLE_" + role + "]"
    else:
        if isRole:
            file_output(fileHandle, lineSpaces + "ROLE.registeredhooks = {", True)
        else:
            file_output(fileHandle, lineSpaces + "ROLE_REGISTERED_HOOKS[ROLE_" + role + "] = {", True)

    if keyLen > 0:
        lastKey = keys[keyLen - 1]
    else:
        file_output(fileHandle, lineSpaces + "    -- Create an empty table here so any hooks in a shared context can be added to it below", True)
        file_output(fileHandle, lineSpaces + "    -- If no hooks are registered in a shared context, this block can be removed", True)

    for key in keys:
        handlers = list(hooks[key].keys())
        handlers.sort()
        # If there are multiple handlers for this hook, structure it as a nested table
        if len(handlers) > 1:
            lastHandler = handlers[len(handlers) - 1]
            file_output(fileHandle, lineSpaces + prefix + "[\"" + key + "\"] = {", True)
            for handlerName in handlers:
                fnName = handlerName
                if hooks[key][handlerName] != None:
                    fnName = hooks[key][handlerName]
                file_output(fileHandle, lineSpaces + "    " + prefix + "[\"" + handlerName + "\"] = " + fnName + "")
                if handlerName != lastHandler:
                    file_output(fileHandle, ",")
                file_output(fileHandle, "\n")
            file_output(fileHandle, lineSpaces + "    }")
        # Otherwise just output the mapping directly
        else:
            handlerName = handlers[0]
            fnName = handlerName
            if hooks[key][handlerName] != None:
                fnName = hooks[key][handlerName]
            file_output(fileHandle, lineSpaces + prefix + "[\"" + key + "\"] = " + fnName)

        if not hasScope and key != lastKey:
            file_output(fileHandle, ",")
        file_output(fileHandle, "\n")

    # If this file has SERVER or CLIENT context scopes we don't need the ending bracket
    # and we want to modify the last line (the return value) so it doesn't output
    # an unnecessary empty line after this
    if hasScope:
        return " "

    file_output(fileHandle, lineSpaces + "}", keyLen == 0)
    return "!PLACEHOLDER!"

for subdir, dirs, files in os.walk(rootdir):
    for file in files:
        path = os.path.join(subdir, file)

        # Skip shared files because generally they don't have enough hooks to justify this
        if file == "shared.lua" or file.startswith("sh_"):
            print("Skipping " + path + ", shared files are not supported")
            continue

        topLevelHooks = {}
        hooks = {}

        # File state
        isRole = False
        hasScope = False
        didReplace = False

        # Scope state
        inScope = False
        scopeSpaces = None

        # Function state
        inFunction = False
        functionSpaces = ""

        # Line state
        skipNext = False
        lastLine = None
        lineSpaces = ""

        # Stats
        skipped = 0
        updated = 0

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

            # local function Something()
            # local Something = function()
            # net.Receive("Something"
            if not inFunction:
                inFunction = ("function " in line) or ("= function(" in line) or ("=function(" in line) or ("net.Receive(" in line)
                if inFunction:
                    space_match = space_pattern.match(line)
                    if space_match:
                        functionSpaces = space_match.group()

            replace = False
            if not inFunction:
                for match_num, match in enumerate(matches, start=1):
                    replace = not namedMatch
                    groups = match.groups()
                    hookName = groups[0]
                    hookId = groups[1]
                    # These hooks need to run before or after registration and un-registration happen so don't move them to the new system
                    if hookName in ["Initialize", "TTTBeginRound", "TTTPrepareRound", "TTTPlayerRoleChanged", "TTTSelectRoles", "TTTTutorialRoleText", "TTTUpdateRoleState", "TTTSyncEventIDs", "TTTSyncWinIDs"]:
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

            # If this is the registration line we want to skip it and the next (assumedly blank) line
            if line.startswith("RegisterRole(ROLE)"):
                skipNext = True
            else:
                # If we're in a SERVER or CLIENT scope
                if inScope:
                    # Save the first line within it's spaces so we know how
                    # many spaces to add to the hook mapping in this scope
                    if scopeSpaces == None or scopeSpaces == "":
                        space_match = space_pattern.match(line)
                        if space_match:
                            scopeSpaces = space_match.group()
                    # And we're ending the scope, print out the hooks that belong to it
                    if line == "end\n" or line == "end":
                        hooksToAdd = len(hooks)
                        lastLine = write_hooks(file, isRole, hooks, lastLine, None, False, scopeSpaces)
                        if hooksToAdd > 0:
                            updated += len(hooks)
                            print("")
                        hooks = {}
                        scopeSpaces = None
                        inScope = False
                # If we're inside another function and it's ending, reset the state
                if inFunction and ((line == functionSpaces + "end\n") or (line == functionSpaces + "end")):
                    inFunction = False

                lastLine = line

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
                    # Setting this to a space fixes extra newlines when an ending block is at the end of the file
                    lastLine = " "
                elif skipNext or namedMatch:
                    skipNext = False
                    line = "!PLACEHOLDER!\n"
                else:
                    # Keep track of the context scope
                    if line.startswith("if SERVER then") or line.startswith("if CLIENT then"):
                        inScope = True
                        hasScope = True
                        if len(hooks) > 0:
                            topLevelHooks = hooks
                            hooks = {}
                    print(line, end='')

        with open(os.path.join(subdir, file), "a") as f:
            if len(topLevelHooks) > 0:
                hooks = topLevelHooks
            hooksToAdd = len(hooks)
            if hooksToAdd > 0:
                updated += hooksToAdd
                lastLine = write_hooks(file, isRole, hooks, lastLine, f, hasScope)
            # Output the registration line at the end
            if isRole:
                if not lastLine.endswith("\n"):
                    f.write("\n")
                if not lastLine.isspace():
                    f.write("\n")
                f.write("RegisterRole(ROLE)")

        print("\tCleaned up " + str(updated) + " hook(s) and skipped " + str(skipped))