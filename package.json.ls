silence-npm = no
symbolic = yes
version = \0.0.2

run = (s)->
	ss = if silence-npm then " -s" else ""
	switch typeof! s
	| \String => "npm run #s" + ss
	| \Array => ["npm run #t" + ss for t in s].join ' && '

symb = (n,t = \bin,nn)-> 
	if symbolic then 
		switch t
		| \bin => \./node_modules/.bin/ + n 
		| \fullbin => \./node_modules/ + (nn || n) + \/bin/ + n
		| \module => \./node_modules/ + n
	else n

istanbul = symb \istanbul
mocha = symb \mocha
_mocha = symb \_mocha \fullbin \mocha
livescript = symb \livescript \module
lsc = symb \lsc
jake = symb \jake
rimraf = symb \rimraf
browserify = symb \browserify
uglifyjs = symb \uglifyjs
istanbul-cli = \./node_modules/istanbul/lib/cli.js
replace = symb \replace

name = 'cuffs'

#start of package.json

name: name
version: version

author: 'Carlo Verschoor'
description: "Cuffs is a library that gives you authority over your javascript values. It let's you check, cast and fix a javascript value to a certain type."
keywords: <[ type force check checking library cuffs handcuffs authority ]>
homepage: 'https://github.com/CarloV/cuffs'
bugs: "https://github.com/CarloV/cuffs/issues"
license: 'MIT'

files: 
	\lib
	\README.md
main: './lib/'

engines: 
	node: ">= 0.12.0"
repository:
	type: \git
	url: "https://github.com/CarloV/cuffs.git"

dependencies: {}

dev-dependencies: 
	mocha: 		'>= 2.4.5'
	chai: 		'>= 3.5.0'
	livescript: '>= 1.4.0'
	browserify: '>= 13.0.0'
	'uglify-js': 	'>= 2.6.2'
	istanbul: 	'>= 0.4.3'
	rimraf: 	'>= 2.5.2'
	'harmony-proxy': '>= 1.0.1'
	replace: '>= 0.3.0'

scripts:
	'prebuild': 		run <[ clean ]>
	'build': 			run <[ build:lib build:browser build:browser-min ]>
	'build:lib': 		"#lsc --output lib --compile src"
	'build:browser': 	"#browserify -r ./lib/index.js:#name > ./browser/#{name}-browser.js"
	'build:browser-min':"#uglifyjs browser/#{name}-browser.js --mangle > browser/#{name}-browser.min.js"

	'package':			"#lsc --compile package.json.ls" #which is seperate from the other build tools, and is not cleaned either. Also watch out with versioning here.

	'prepublish': 		run <[ test build ]>

	'pretest': 			run \build:lib
	'test': 			run \test:bare
	'test:bare':		"#mocha --compilers ls:#livescript --harmony_proxies"
	'posttest': 		'git checkout -- lib'

	'precoverage': 		run \build:lib
	'coverage': 		run \coverage:bare
	'coverage:bare':	"node --harmony_proxies #istanbul-cli cover #_mocha -- --compilers ls:#livescript -R nyan"
	'postcoverage': 	'git checkout -- lib'

	'clean': 			run <[ clean:lib clean:browser clean:coverage ]>
	'clean:lib': 		"#rimraf lib/*"
	'clean:browser': 	"#rimraf browser/*"
	'clean:coverage': 	"#rimraf coverage"

	'preversion': 		run \test
	'version':			run <[ version:apply build git:add]> 
	'version:apply': 	"#lsc version"
	'postversion': 		"git push && git push --tags"

	'git:add':          "git add ."