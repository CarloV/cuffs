require! {replace, './package.json': {version}}
replace do
    regex: /(version\s*=\s*)(\\\d+\.\d+\.\d+)/gi
    replacement: "$1\\#version"
    paths: <[ . ]>
    recursive: yes
    include: \*.ls
    silent: yes

