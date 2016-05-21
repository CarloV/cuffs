Cuffs = require \.. #mocha --compilers ls:livescript
{expect} = require \chai
they = it

OO = null
OOProxy = null
they 'should have the correct version' ->
    expect(Cuffs.version)to.equal (require \../package.json)version

describe 'Cuffs' ->
    before ->
        OO := Cuffs!
        expect(OO)to.be.a \function

    they 'should only allow strings to be passed' ->
        expect(OO \String)to.be.a \function
        expect(-> OO 1)to.throw Error
        expect(-> OO!)to.throw Error
        expect(-> OO {})to.throw Error

    describe 'Sync statements' ->
        o = (t,g=[],b=[])->
            <- they "should recognize the type #t"
            force = OO t
            for let gg in g
                expect(force gg)to.eql gg
            for let bb in b
                expect(-> force bb)to.throw Error

        n = (t)->
            <- they "should not parse the type #t"
            expect(-> OO t)to.throw Error

        describe 'Literals' ->
            o \String       [ \String \0 \! '' ]                        [0 void {} [] undefined, true ->]
            o \Number       [ -1 0 1 Infinity, 0.5 Math.PI]             [\0 void {} [] true undefined, ->]
            o do 
                \Object       
                [ 
                    {}
                    {lol: \poop}
                    new
                        @foo = \bar
                        @baz = \qux
                ]                        
                [0 \0 void [] true undefined, ->]

            o \Array        [ [], <[ lol ]> , [1 to 10]]                [0 \0 void {} true undefined,->]
            o \Boolean      [ true false ]                              [0 \0 void {} [] undefined, ->]
            o \Date         [new Date!]                                 [0 \0 void {} [] true undefined, ->]
            o \Integer      [0 1 Infinity]                              [0.5 Math.PI]
            o \Null         [null]                                      [0 \0 {} [] true undefined, ->]
            o \Undefined    [undefined, void]                           [0 \0 {} [] true ->] 
            o \NaN          [NaN, undefined, void, \hai, 'NaN', 0/0]    [123, \123]
            o \Function     [->, o]                                     [0 \0 void {} [] true undefined]
            o \Error        [new Error 'poop']                          [0 \0 void {} [] true undefined]
            o \Truthy       [true [\lol], {foo:\bar}, ->]               [0 false void undefined, '']
            o \Untruthy     [0 false, '']                               [true [\lol], {foo:\bar}, ->]
            o \RegExp       [/foo/, new RegExp \foo]                    [\foo 0 void {} [] true undefined, ->]
            o \*            [0 \0 {} [] true, undefined, void ->]
            o \All          [0 \0 {} [] true, undefined, void ->]
            o \Existent     [0 \0 {} [] true, ->]                       [undefined, void]
            o \Inexistent   [undefined, void]                           [0 \0 {} [] true, ->] 
            o \<String>     [\0]                                        [0]
            n \<>

            o \SomeRandomType [new class SomeRandomType]              [0 \0 {} [] true, undefined, void ->]

        describe 'TypeCasting' ->
            they "should recognize the type !Number" ->
                force = OO \!Number 
                expect(force 0)to.equal 0
                expect(force \0)to.equal 0
                expect(force \123.456)to.equal 123.456
                expect(force false)to.equal 0
                expect(-> force \a)to.throw Error

            they "should recognize the type !String" ->
                force = OO \!String
                expect(force 0)to.equal \0

            they "should recognize the type !Integer" ->
                force = OO \!Integer
                expect(force 0)to.equal 0
                expect(-> force \a)to.throw Error

            they "should recognize the type !Boolean" ->
                force = OO \!Boolean
                expect(force 0)to.equal false
                expect(force 1)to.equal true

            they "should recognize the type !Date" ->
                force = OO \!Date
                d = new Date!
                expect(force d)to.eql d
                expect(force 0)to.eql new Date 0

        describe 'Parenthesis' ->
            o '(String)', [\String], [[\String]]
            n 'String)'
            n '(String'

        describe 'Arrays' ->
            o '[]', [[],[void],[null],[void, void, undefined, null]], [[1],<[ foo bar ]>]
            o '[String]', [[],<[ foo ]>, <[ foo bar ]>], [[1],[\foo, void], [void, \foo]]
            o '[[String]]', [[],[[]],[<[foo bar]>, <[foo bar baz]>]]
            n '[String,String]'
            n '[(String]'
            n '[String)]'
            n '[(String])'
            n '([String)]'
            n '(String]'
            n '[String)'

        describe 'Tuples' ->
            o '()', [[]], [[1],[void],[undefined],<[ foo bar ]>,{}]
            o '(,)', [[]], [[1],[void],[undefined],<[ foo bar ]>,{}]
            o '(String,)', [[\a]], [[], [1],[void],[undefined],<[ foo bar ]>]
            o '(String,Number)', [[\a, 0]], [[], [1],[void],[undefined],<[ foo bar ]>, [0, \a]]
            o '(String,Number,(String,Number))', [[\a, 0, [\a, 0]]], [[\a, 0, \a, 0],[[\a, 0], \a, 0],[[\a, 0,], [\a, 0]]]
            o '((String,Number),(String,Number))',[[[\a, 0,], [\a, 0]]]
            n '(String,'
            n 'String,)'
            n '([String,)'
        
        describe 'Strings' ->
            o '"test"', [\test], [\othertest]
            o "'test'", [\test], [\othertest]
            o '"0"', [\0], [0]
            o "'\\'\"'", [\'"]
            o '"\\"\'"', [\"']

        describe 'Numbers' ->
            o '0', [0], [\0]

        describe 'Or' ->
            o 'String | Number', [0, \0], [void, undefined, true, false, [], {}, ->]
            o '[String | Number]', [[\a, 0, \a, 0]]
            o '(String | Number,)', [[\a], [0]]
            o '(String | Number, Array | Number)', [[\a, 0], [0, []]]

        describe 'And' ->
            o 'Number & Not String', [0, Infinity], [\lol void, undefined, true, false, [], {}, ->]
            o 'Not Integer & Number', [Math.PI, 0.5], [0 10]
            o 'String & "String"', [\String], [\string]
            they "should recognize the type String & !Number" ->
                force = OO 'String & !Number'
                expect(force \0)to.equal 0
                expect(-> force 0)to.throw Error
                expect(-> force true)to.throw Error

        describe 'Maybe' ->
            o 'Maybe String', [void undefined, \a], [true]
            o 'Maybe Maybe String', [void undefined, \a], [1 true false [], {}, ->]
            o 'Maybe String | Number', [void undefined, \a 1], [true false [], {}, ->]
            o 'String | Maybe Number', [void undefined, \a 1], [true false [], {}, ->]
            o 'Maybe', [\0 0 void {} [] undefined, true], []

        describe 'Not' ->
            o 'Not String', [0 void {} [] undefined, true ->], [ \String \0 \! '' ]
            o 'Not (String,Number,(String,Number))', [[\a, 0, \a, 0],[[\a, 0], \a, 0],[[\a, 0,], [\a, 0]]], [[\a, 0, [\a, 0]]]
            o '(Not String) | (Not Number)', [\a, [], 0], []
            o 'Not String | Not Number', [\a, [], 0], []
            o 'Not Not String', [ \String \0 \! '' ], [0 void {} [] undefined, true ->]
            o 'Not (Integer | Not Number)', [Math.PI, 0.5], [0 1 Infinity]
            o 'Not', [], [\0 0 void {} [] undefined, true ->]

        describe 'Objects' ->
            o '{}', [{}], [{foo:\bar}]
            o '{foo:String}', [{foo:\bar}]
            o '{foo:String, baz: Number}', [{foo:\bar, baz:0}]
            o '{foo}', [{foo:\bar},{foo:1}], [{},{foo:void}]
            o '{foo:}', [{foo:\bar},{foo:1}], [{},{foo:void}]
            o '{foo,baz}',[{foo:\bar, baz:0}], [{},{baz:1},{foo:0},{bar:\lol}]
            o '{foo:{bar,baz},lol,poop:String,ok}', [{foo:{bar:0,baz:0},lol:0,poop:\poop,ok:yes}]
            o '{foo:Maybe String}', [{foo:\bar},{}]
            o '{\\::"colon"}', [{':':"colon"}]
            n '{foo'
            n '{foo:'
            n '[{foo:]'
            describe 'Object Ellipsis' ->
                o '{...}', [{foo:\bar},{foo:\bar,baz:0},{}]
                o '{foo,...}',[{foo:\bar,baz:0}],[{},{baz:0}]
                o '{foo,...String}', [{foo:\bar,baz:\qux},{foo:\bar}],[{},{foo:\bar,baz:0}]

            describe 'Object Class Types' ->
                o 'Array{0:String,...}', [[\lol],[\lol 1 2]], [[],[1 2 \lol],[1 \lol]]
                o '[String | Number]{0:String,...}', [[\lol 1 2],[ \lol \wow \what \nice \is \this ]], [[1 2 3],[1 \lol \ok]]
                o '[String | Number]{length:5,...}', [[ 1 to 5 ],[\a to \e]], [[1 to 4],[\a to \f]]

        describe 'Comments' ->
            o 'String#foo' [\foo], [0]
            o '(String#foo, String#bar)', [[\foo \bar]]
            o do
                '''
                /* here some comments on this
                   very nice structure */
                (String,Number) | /* we want this normally */
                (Number,String) | /* but this is also good */
                (String,)         /* or this one */
                ''' 
                [[\a 1], [1 \a], [\A]] 
                [[\a \1], [1], [\a 1 2], []] 


    describe 'Async Statements' -> 
        o = (t,f)->
            <- they 'should recognize the type ' + t 
            f OO t

        n = (t)->
            <- they 'should not recognize the type ' + t 
            expect(-> OO t)to.throw Error

        describe 'Normal Arrows' ->
            o \-> (force)->
                good = force !->
                good!
                expect(-> good \lol)to.throw Error
                bad = force -> \lol
                expect bad .to.throw Error 
                expect(-> force \SomethingRandom)to.throw Error  

            o 'String ->' (force)->
                good = force (a)!->
                good \a
                expect good .to.throw Error
                expect(-> good \a, \b)to.throw Error
                expect(-> good 0)to.throw.Error

            o '( String ) ->' (force)->
                good = force (a)!->
                good \a
                expect good .to.throw Error
                expect(-> good \a, \b)to.throw Error

            o '-> String' (force)->
                good = force -> \lol
                expect(good!)to.equal \lol
                bad = force -> 1
                expect(-> bad!)to.throw Error

            o '(String, Number) -> String' (force)->
                good = force (a,b)-> a + b.to-string!
                expect(good \a 2)to.equal \a2

                expect(-> good \a \b)to.throw Error

            o '(...) -> Number' (force)->
                good = force -> &length
                expect(good 1 \b [\c])to.equal 3

            o '(...Number) -> Number' (force)->
                good = force -> &length
                expect(good 1 2 3)to.equal 3
                expect(good 1 2 3 4 5)to.equal 5
                expect(good!)to.equal 0

                expect(-> good \a \b)to.throw Error

            o '(String,String,...Number) -> [String | Number]' (force)->
                good = force (...a)-> a 
                expect(good \a \b 1 2 3).to.eql [\a \b 1 2 3]
                expect(good \a \b).to.eql [\a \b]
                expect(-> good \a).to.throw Error
                expect(-> good!).to.throw Error

            o '(String,...Number, String) -> [String | Number]' (force)->
                good = force (...a)-> a 
                expect(good \a 1 2 3 \b).to.eql [\a 1 2 3 \b]
                expect(good \a \b).to.eql [\a \b]

            o '(...Number,String, String) -> [String | Number]' (force)->
                good = force (...a)-> a 
                expect(good 1 2 3 \a \b).to.eql [1 2 3 \a \b]
                expect(good \a \b).to.eql [\a \b]

            o 'String -> String -> String' (force)->
                good = force (a)-> (b)-> a + b 
                expect(good(\foo)(\bar)).to.equal \foobar
                expect(-> good(\foo)(0)).to.throw Error
                bad = force (a)-> (b)-> 0
                expect(-> bad(\foo)(\bar)).to.throw Error 

            o '(String -> String) -> String' (force)->
                good = force (a)-> a \bar
                expect(good((b)-> \foo + b)).to.equal \foobar
                expect(-> good(\foo)).to.throw Error
                bad = force (a)-> (b)-> a + b 
                expect(-> bad(\foo)(\bar)).to.throw Error

            o '(Number, Number) -> (Number, Number) -> Number' (force)->
                good = force (a,b)-> (c,d)-> a + b + c + d
                expect(good(1 2)(3 4)).to.equal 10 

            o '(Number -> Number -> Number) | ((Number, Number) -> Number)', (force)->
                good = force (+)
                expect(good 1 2).to.equal 3
                expect(good(1)(2)).to.equal 3
                expect(-> good \foo).to.throw Error
                expect(-> good \foo \bar).to.throw Error

            #here follows a nice arithmetic relationship: (A -> B) & (C -> D)   =>   (C & A) -> (B & D)
            o '(!Number -> String) & (String -> !Number)', (force)-> #this thing, even though it works, is kind of troublesome, better to use & sync inside the arguments
                good = force (a)->a.to-string!
                expect(good \1)to.equal 1
                expect(-> good 1)to.throw Error 
                bad = force (a)-> +a 
                expect(-> bad \1)to.throw Error

            o 'String & !Number -> String & !Number', (force)-> #same as above, but the nicer way
                good = force (a)->a.to-string!
                expect(good \1)to.equal 1
                expect(-> good 1)to.throw Error 
                bad = force (a)-> +a 
                expect(-> bad \1)to.throw Error

            o 'Maybe (->)' (force)->
                expect(force void).to.equal void
                expect(force null).to.equal null
                good = force ->
                good!
                bad = force -> \foo
                expect bad .to.throw Error

            o '{foo: String -> String, bar: (!Number, !Number) -> Number}' (force)->
                good = force do 
                    foo: (s)->s + \!
                    bar: (+)
                expect(good.foo \foo)to.be.equal \foo!
                expect(good.bar 1 2)to.be.equal 3
                expect(good.bar \1 \2)to.be.equal 3
                expect(-> good.foo 100)to.throw Error
                expect(-> good.bar \a \b)to.throw Error

            o '(,String,,,Number)->' (force)->
                good = force ->
                expect(good null,\lol,,,5).to.equal undefined

            o '-> Function' (force)->
                good = force -> -> -> \lol 
                expect(good!!!).to.equal \lol

            they "should adhere to the initial 'this'" ->
                class Foo  
                    ->
                        @baz = \baz
                    bar: OO '-> String' -> @baz

                foo = new Foo 
                expect(foo.bar!)to.be.equal \baz

            n '(...String,Number,...String)->'

        describe 'Curried Arrows' ->
            o \--> (force)->
                good = force !->
                good!
                expect(-> good \lol)to.throw Error
                bad = force -> \lol
                expect bad .to.throw Error 
                expect(-> force \SomethingRandom)to.throw Error  

            o \!--> (force)->
                good = force !->
                good!
                expect(-> good \lol)to.throw Error
                bad = force -> \lol
                expect bad .to.throw Error 
                expect(-> force \SomethingRandom)to.throw Error 

            o '(String)-->' (force)->
                good = force !->
                expect(-> good!)to.throw Error
                good \lol
                bad = force -> \lol
                expect bad .to.throw Error 
                expect(-> force \SomethingRandom)to.throw Error  

            o '(String)!-->' (force)->
                good = force !->
                expect(-> good!)to.throw Error
                good \lol
                bad = force -> \lol
                expect bad .to.throw Error 
                expect(-> force \SomethingRandom)to.throw Error  

            o '(String, Number) --> String' (force)->
                good = force (a,b)--> a + b.to-string!
                expect(good \a 2)to.equal \a2
                expect(good(\a)(2))to.equal \a2
                expect(-> good \a 2 3)to.throw Error
                expect(-> good \a \b)to.throw Error
                expect(-> (good \a)!)to.throw Error

                bad = force (a,b)-> a + b.to-string!
                expect(bad \a 2)to.equal \a2
                expect(-> bad(\a)(2))to.throw Error

                worse = force (a)-> a
                expect(worse \a)to.throw Error

            o '(String, Number) !--> String' (force)->
                good = force (a,b)--> a + b.to-string!
                expect(good \a 2)to.equal \a2
                expect(good(\a)(2))to.equal \a2
                expect(-> good \a 2 3)to.throw Error
                expect(-> good \a \b)to.throw Error
                expect(-> (good \a)!)to.throw Error

                notbad = force (a,b)-> a + b.to-string!
                expect(notbad \a 2)to.equal \a2
                expect(notbad(\a)(2))to.equal \a2

                worse = force (a)-> a
                expect(worse \a)to.throw Error

            o '(String, Maybe String) --> String' (force)->
                good = force (a,b = \poop)--> a + b
                expect(good \a \b)to.equal \ab 
                expect((good \a)!)to.equal \apoop

            o '(String, Maybe String) !--> String' (force)->
                good = force (a,b = \poop)-> a + b
                expect(good \a \b)to.equal \ab 
                expect((good \a)!)to.equal \apoop

            they "should adhere to the initial 'this'" ->
                class Foo  
                    ->
                        @baz = \baz
                    bar: '(String, String) --> String' `OO` (a,b)--> @baz + a + b
                    qux: '(String, String) !--> String' `OO` (a,b)-> @baz + a + b

                foo = new Foo 
                expect(foo.bar \a \r)to.be.equal \bazar
                expect(foo.qux \a \r)to.be.equal \bazar
                expect(foo.bar(\a)(\r))to.be.equal \bazar
                expect(foo.qux(\a)(\r))to.be.equal \bazar

            n '(String, ..., Number) --> '
            n '(String, ...Integer, Number) !--> '

        describe 'Checking `this` on a function' ->
            o 'SomeClass @ Function' (force)->
                class SomeClass
                    ->
                        @foo = 5

                    bar: force -> @foo

                S = new SomeClass
                expect(S.bar!)to.equal 5
                expect(SomeClass::bar)to.throw Error

            o 'SomeClass @ (!Number,!Number) -> Number' (force)->
                class SomeClass
                    ->
                        @foo = 5

                    bar: force (a,b)-> @foo + a + b 

                S = new SomeClass
                expect(S.bar \1 \5)to.equal 11


            o 'SomeClass @ ((!Number,!Number) !--> Number)' (force)->
                class SomeClass
                    ->
                        @foo = 5

                    bar: force (a,b)-> @foo + a + b 

                S = new SomeClass
                expect(S.bar \1 \5)to.equal 11
                expect(S.bar(\2)(\4))to.equal 11

            o '{foo: Number, ...} @ ((!Number,!Number) !--> Number)' (force)->
                class SomeClass
                    ->
                        @foo = 5

                    bar: force (a,b)-> @foo + a + b 

                S = new SomeClass
                expect(S.bar \1 \5)to.equal 11
                expect(S.bar(\2)(\4))to.equal 11


    describe 'Custom Types' ->
        they 'should be able to add custom types based on functions' ->
            OO2 = Cuffs do
                custom-types: 
                    Foo: (err)-> -> if it is \foo then return it else err 'Where is the foo?'
                    '!Foo': -> -> \foo

            expect(OO2)to.be.a \function
            expect(OO2(\Foo \foo))to.be.equal \foo 
            expect(-> OO2(\Foo \bar))to.throw Error
            expect(OO2(\!Foo)(\lol))to.be.equal \foo

            foo-fun = OO2('!Foo -> Foo')(-> it)
            expect(foo-fun \bar)to.be.equal \foo
            expect(-> foo-fun!)to.throw Error

            foo-very-fun = OO2('(...!Foo) -> [Foo]')((...foo)-> foo)
            expect(foo-very-fun \lol \wow \so \very \nice \is \this)to.be.eql <[ foo foo foo foo foo foo foo ]>

        they 'should be able to add custom types based on strings' ->
            OO2 = Cuffs do
                custom-types: 
                    Foo: \'foo'
                    '!Foo': (a,b)-> \foo
                    'O->': '"flower"'

            expect(OO2)to.be.a \function
            expect(OO2(\Foo \foo))to.equal \foo 
            expect(-> OO2(\Foo \bar))to.throw Error
            expect(OO2(\!Foo)(\lol))to.equal \foo

            foo-fun = OO2('!Foo -> Foo')(-> it)
            expect(foo-fun \bar)to.equal \foo
            expect(-> foo-fun!)to.throw Error

            foo-very-fun = OO2('(...!Foo) -> [Foo]')((...foo)-> foo)
            expect(foo-very-fun \lol \wow \so \very \nice \is \this)to.eql <[ foo foo foo foo foo foo foo ]>

            expect(-> OO2('O->',\flower))to.throw Error
            expect(OO2('<O-\\>>',\flower))to.equal \flower


        they 'should be able to add custom types based on regex' ->
            OO2 = Cuffs do
                custom-types: 
                    '/Class(\\w+)/': (mat)-> (err)-> -> if it@@display-name is mat.1 then it else err "Not an instance of #{mat.1}"
                    '/Foo|Bar|Baz/': (mat)-> (err)-> -> if it is mat.0 then it else err "Not #{mat.0}"
                    '/Global_(\\w+)/': (mat)-> (err,it)-> if it is global[mat.1] then it else err "Not the global variable #{mat.1}"
            class Foo
                (@foo)->
            a = new Foo \bar
            
            expect(OO2)to.be.a \function
            expect(OO2('ClassFoo',a))to.eql a 
            expect(OO2('Foo',\Foo))to.eql \Foo
            expect(-> OO2('Bar',\Foo))to.throw Error
            expect(OO2('Global_global',global))to.eql global

        they 'should be able to add custom types in sequence' ->
            OO2 = Cuffs do
                custom-types: 
                    do
                        Foo: \'foo'
                        Bar: \'bar'
                    do
                        FooBar: 'Foo | Bar'

            expect(OO2)to.be.a \function
            FB = OO2 \FooBar
            expect(FB \foo)to.equal \foo
            expect(FB \bar)to.equal \bar 
            expect(-> FB \foobar)to.throw Error

        they 'should be able to remove custom types in sequence' ->
            OO2 = Cuffs do
                custom-types: 
                    do
                        Foo: \'foo'
                        Bar: \'bar'
                        Baz: \'baz'
                    do
                        Foo: false
                        Bar: true

            expect(OO2)to.be.a \function
            expect(-> OO2 \Foo \foo)to.throw Error
            expect(OO2 \Bar \bar)to.equal \bar 
            expect(OO2 \Baz \baz)to.equal \baz

        they 'should be able to add custom types using #modify-types' ->
            OO2 = Cuffs do
                custom-types: 
                    Foo: \'foo'
                    Bar: \'bar'
                    Baz: \'baz'
            
            OO2.modify-types do 
                FooBar: 'Foo | Bar'
                Baz: null 

            expect(OO2)to.be.a \function
            FB = OO2 \FooBar
            expect(FB \foo)to.equal \foo
            expect(FB \bar)to.equal \bar 
            expect(-> FB \foobar)to.throw Error
            expect(-> OO2 \Baz \baz)to.throw Error

        they 'should error at any invalid custom type' ->
            h = (u)-> -> Cuffs custom-types: {foo: u}
            expect(h 1)to.throw Error 
            expect(h void)to.throw Error 
            expect(h {})to.throw Error 

    describe 'Proxy Support' -> #note that this is tested on node with a shim, probably.
        before ->
            OOProxy := Cuffs {+use-proxies}
            expect(OOProxy)to.be.a \function
        
        they 'should force types on arrays' ->
            arr = OOProxy('[Number]',[1 2 3])
            #expect(typeof! arr)to.equal \Array
            arr.push 4 
            expect(-> arr.push \5)to.throw Error
            expect(arr.length)to.equal 4

            arr = OOProxy('[[Number]]',[[1 2] [3 4 5]])
            arr.push [6 7 8]
            arr[*-1]push 9
            expect(-> arr.push 10)to.throw Error 
            expect(-> arr.push [\B])to.throw Error 
            expect(-> arr[*-1]push \A)to.throw Error


        they 'should force types on tuples' ->
            arr = OOProxy('(Number,Maybe String,Number | String)',[1 \b 3])
            expect(-> arr.push 4)to.throw Error
            expect(-> arr.unshift 5)to.throw Error
            expect(-> arr.pop!)to.throw Error
            arr.2 = \C
            arr.foo = \bar
            delete arr.foo
            expect(-> arr.1 = 2)to.throw Error
            expect(-> arr.length = 4)to.throw Error
            expect(-> delete arr.2)to.throw Error
            expect(arr.slice 0).to.eql [1 \b \C]
            delete arr.1
            expect(arr.slice 0).to.eql [1 void \C]
            arr.length = 3

        they 'should force types on objects' ->
            obj = OOProxy('{foo:Number,bar:String}',{foo: 1, bar: "lol"})
            obj.foo = 5
            expect(-> obj.baz = "LOL")to.throw Error
            expect(-> obj.foo = "LOL")to.throw Error

            obj = OOProxy('{foo:Number,bar:String, ...String}',{foo: 1, bar: "lol"})
            obj.foo = 5
            obj.baz = "LOL"
            expect(-> obj.baz = 5)to.throw Error
            expect(-> obj.foo = "LOL")to.throw Error

            obj = OOProxy('{foo:!Boolean,...!Boolean}',{+foo,-bar})
            delete obj.foo
            expect(obj.foo)to.equal false
            delete obj.bar 
            expect(obj.bar)to.equal undefined

            obj = OOProxy('[Number]{foo:Maybe Number,bar:Maybe String,...}',[1 2 3])
            obj.foo = 5
            obj.bar = "LOL"
            delete obj.bar
            obj.baz = 5
            delete obj.baz
            obj.3 = 4
            expect(-> obj.4 = \String)to.throw Error
            expect(-> obj.foo = "LOL")to.throw Error







        