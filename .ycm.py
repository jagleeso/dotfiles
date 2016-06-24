import os

def FlagsForFile(filename, **kwargs):

    flags = [
        '-Wall',
        '-Wextra',
        '-Werror'
        '-pedantic',
        '-I',
        '.',
        '-isystem',
        '/usr/include',
        '-isystem',
        '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include',
        '-isystem',
        '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/../lib/clang/5.1/include',
        '-isystem',
        '/usr/local/include',
        '-isystem',
        '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/../lib/c++/v1',
    ]
    import pprint
    pprint.pprint(kwargs)

    # data = kwargs['client_data']
    # filetype = data['&filetype']
    _, file_extension = os.path.splitext(filename)

    if file_extension == '.c':
        flags += ['-xc']
    elif file_extension in set(['.cpp', '.h']):
        flags += ['-xc++']
        flags += ['-std=c++11']
    elif file_extension == '.objc':
        flags += ['-ObjC']
    else:
        flags = []

    import pprint
    pprint.pprint(file_extension)

    import pprint
    pprint.pprint(flags)

    return {
        'flags':        flags,
        'do_cache': True
    }
