require! {'./multi-array-explorer': {MultiArrayExplorer}}
id = -> it
YES = -> true
version = \0.0.3
#idea
#you force a type on a structure
#it gives an error whenever a structure fails (even async)
#otherwise nothing happens.
#when proxies are turned on, the structure literally stays in place
#otherwise it only stays there for functions

$typeof = (a)-> #this is needed to look behind a shimmed Proxy
    return typeof! a unless a? and a@@?
    if a@@name
        return that
    else if a@@toString?
        mat = a@@toString!match /^function\s*(\w+)\(/
        if mat and mat.length == 2
            return mat.1
    return typeof! a

shallow-copy = (obj)->
        nobj = {}
        for k,v of obj
            nobj[k] = v 
        nobj

lits =
    Integer:   (err)-> -> if $typeof(it) is \Number and Math.floor(it) is it    then it else err 'Not an Integer'
    NaN:       (err)-> -> if is-NaN it                                          then it else err 'Not a Not a Number' 
    Truthy:    (err)-> -> if !!it                                               then it else err 'Not Truthy'
    Untruthy:  (err)-> -> if !it                                                then it else err 'Not Untruthy'
    Existent:  (err)-> -> if it?                                                then it else err 'Not Existent'
    Inexistent:(err)-> -> if !it?                                               then it else err 'Not Inexistent'
    '*': (err)-> -> it
    All: (err)-> -> it

    '!Number': (err)-> -> if not is-NaN it then +it else err 'Not a !Number'
    '!String': (err)-> -> '' + it# throw new Error 'Cannot cast #it to a String'
    '!Integer': (err)-> -> if not is-NaN it then Math.round(+it) else err 'Not an !Integer'
    '!Boolean': (err)-> -> !!it
    '!Date':    (err)-> -> new Date +it || it


modifiers =
    Maybe: (a,err)-> (v)-> 
        try 
            lits.Inexistent(err)(v)
        catch 
            return a v
            
                    

    Not: (a,err)-> (v)-> #only works in sync mode
        try 
            av = a v #needs to be more async
        catch
            return v
        err 'Not Not'

or-helper =
    (e,A,B)-> ->
        try
            Af = A ...
        catch {message}
            m1 = message
            _Af = false
        
        try
            Bf = B ...
        catch {message}
            m2 = message
            _Bf = false

        if _Af == false and _Bf == false
            throw new Error m1 + ' And ' + m2
        else if _Af == false and _Bf != false
            return Bf
        else if _Bf == false and _Af != false
            return Af 
        else if $typeof(Af) is \Function and $typeof(Bf) is \Function
            return or-helper e, Af,Bf
        else #2 answers, then we just or them as usual
            return Af || Bf

and-helper =
    (e, A,B)-> -> B A ...

Cuffs = ({custom-types = {}, use-proxies = false, on-error} = {})-> 
    modes = {}
    literals = lits
    prox = Proxy
    _up = ->
        use-proxies := it
        if use-proxies and typeof window is \undefined
            prox := require \harmony-proxy

        if use-proxies and typeof prox is \undefined
            use-proxies := false
        use-proxies


    _up use-proxies

    open-tag = (t)-> if t is \array then \[ else if t is \object then \{ else \(

    go-down = (arr,pos,u = <[ parenthesis tuple object array]>)->
        arr.down!
        arr.prop \closePos pos
        if arr.prop(\type) in u
            throw new Error "Cuffs Syntax Error - Unclosed #{open-tag arr.prop(\type)} tag"

    OOError = (str,open-pos,close-pos,message)!--> 
        throw new Error "Cuffs Error - #message - From position #open-pos to position #close-pos of #str"

    process-custom-types = (o)->
        O = {}
        for let k,v of o
            switch $typeof v
            | \String => 
                p = parse-to-function parse-to-array(v), OOError(v)
                O[k] = (err)-> p
            | \Function => 
                if v.length == 2
                    O[k] = (err)-> (w)->v err,w 
                else
                    O[k] = v 
            | \Boolean \Null =>
                O[k] = null unless v
            | _ => throw new Error "Cuffs Parse Error - Can't parse the custom type #k"
        
        O

    parse-to-array = (str)->
        modus = \normal
        a = []
        a.type = \parenthesis
        a.mode = \normal
        arr = new MultiArrayExplorer a, [0]
        L = 0
        SL = str.length
        f =(s,listen-to,mode) ->
            switch $typeof listen-to
            | \String => 
                if !s.index-of listen-to
                    if no isnt mode arr, L
                        return s.slice listen-to.length

            | \RegExp => 
                if !s.search listen-to
                    m = s.match listen-to
                    if no isnt mode arr, m , L
                        return s.slice m.0.length

            | \Array =>
                for l in listen-to
                    fr = f s,l,(mode _, l, _)
                    if fr isnt no
                        return fr

            | _ => 
                throw new Error "Cuffs Parse Error - Mode key '#{s.to-string!}' of type #{$typeof s} is not supported"
            no

        rec = (s)->
            m = modes[arr.get-inherited-parent-prop \mode]
            for [listen-to,mode] in m 
                r = f s, listen-to, mode 
                if r isnt no 
                    return r

        while str.length
            L = SL - str.length
            str |>= rec

        throw new Error "Cuffs Syntax Error - You closed too many parentheses" if arr.index.length == 0
        while arr.index.length > 1
            go-down arr, SL - 1
        arr.arr

    parse-to-function = (arr,err,parent-polymf = YES,temp_polym = {})->
        e = err(arr.pos || 0, arr.close-pos || arr.pos || 0)

        _temp_polym = {}
        clean = -> 
            _temp_polym := shallow-copy temp_polym
        clean!

        polymf = (ltr,typ)-> #note that with this construction, proxies will not recognize polymorphisms (unless the proxy checks the whole structure again instead of the single value that is added)
            if _temp_polym[ltr]?
                return that is typ

            ppmf = parent-polymf(ltr,typ)
            _temp_polym[ltr] = typ if ppmf is true
            return ppmf

        polymf-force = (ltr,typ)->
            if _temp_polym[ltr]?
                return that is typ

            _temp_polym[ltr] = typ
            return true

        sf = (u,pmf = polymf)->
            switch $typeof u
            | \Array => return parse-to-function u, err, pmf, shallow-copy _temp_polym
            | \Function => return u e
            | _ => return lits.Inexistent e #only Undefined will be here

        <- (x) ->
            r = x!
            -> 
                try
                    R = r ...
                catch
                    clean!
                    throw e 
                clean!
                R

        switch arr.type 
        | \parenthesis => 
            if arr.length == 0
                return -> if $typeof it is \Array and it.length == 0 then it else e 'Not an empty Tuple'
            sf arr.0
        | \array =>
            g = sf arr.0
            prelim-check = (v)-> 
                e 'Not an Array' unless v instanceof Array #if proxy is shimmed the typeof! doesnt work properly anymore
                [g .. for v]

            return prelim-check unless use-proxies
            return (o)->
                O = prelim-check o
                new prox do 
                    O 
                    set: (target, prop, val, recv)->
                        #TODO: add a new total check solely for polymorphisms
                        if isNaN prop or +prop < 0 or (+prop)%1 isnt 0
                            target[prop] = val
                            return true
                        target[prop] = g val
                        true

        | \object =>
            na = {}
            ks = []
            typed = sf lits\*
            ellipsis = false
            for a in arr
                if $typeof(a) is \String
                    let k = a
                        ks.push k
                        na[k] = sf lits.Existent
                    continue
                switch a.type
                | \property => let k = a.0, v = a.1
                    ks.push k
                    if !v?
                        na[k] = sf lits.Existent
                    else
                        #sv = sf v
                        na[k] = sf v#(o,O)-> O[k] = sv o[k]]
                | \object-type => typed = sf a.0
                | \ellipsis =>
                    if a.length == 0
                        ellipsis = id
                    else
                        ellipsis = sf a.0

            prelim-check = (o)->
                O = typed o 
                for k,n of na 
                    O[k] = n o[k]
                if ellipsis != false
                    for k of o when k not in ks
                        O[k] = ellipsis o[k]
                else
                    for k of o when k not in ks
                        e "Didn't expect the key #k inside the object"
                O

            return prelim-check unless use-proxies

            return (o)->
                O = prelim-check o
                new prox do 
                    O 
                    set: (target, prop, val, recv)->
                        #TODO: add a new total check solely for polymorphisms
                        if na[prop]?
                            target[prop] = that val
                        else if ellipsis != false
                            target[prop] = ellipsis val
                        else
                            e "Key can't be inside this object"
                            #return false
                        true

                    deleteProperty: (target,prop)->
                        #TODO: add a new total check solely for polymorphisms
                        if na[prop]?
                            tv = that void
                            if tv?
                                target[prop] = that
                            else
                                delete target[prop]
                        else
                            delete target[prop]
                        true


        | \tuple =>
            preev = [sf arr[i] for i til arr.length]
            prelim-check = (v)-> 
                e 'Not an Array' unless v instanceof Array #if proxy is shimmed the typeof! doesnt work properly anymore
                e "Tuple length doesn't match" if v.length isnt arr.length
                [preev[i] v[i] for i til v.length]

            return prelim-check unless use-proxies
            return (o)->
                O = prelim-check o
                new prox do 
                    O 
                    set: (target, prop, val, recv)->
                        #TODO: add a new total check solely for polymorphisms
                        if prop is \length
                            e "Tuple length doesn't match" unless val == arr.length 
                            target[prop] = val
                            return true

                        if isNaN prop or +prop < 0 or (+prop)%1 isnt 0
                            target[prop] = val
                            return true

                        target[prop] = preev[prop] val
                        true

                    deleteProperty: (target,prop)->
                        #TODO: add a new total check solely for polymorphisms
                        if isNaN prop or +prop < 0 or (+prop)%1 isnt 0
                            delete target[prop]
                            return true
                        
                        target[prop] = preev[prop](void)
                        return true

        | \argument-tuple =>
            if arr.length == 0
                return -> if $typeof(it) is \Array and it.length == 0 then it else e 'Arguments should be an empty tuple'
            else 
                ellipsii = [a for a in arr when a? and a.type is \ellipsis]length
                if ellipsii == 0
                    preev = [sf arr[i] for i til arr.length]
                    return (v)-> 
                        e "Argument Tuple length doesn't match" if v.length isnt arr.length
                        [preev[i] v[i] for i til arr.length]

                else if ellipsii == 1
                    j = 0
                    fa = []
                    la = []
                    for i til arr.length 
                        a = arr[i]
                        if a? and a.type is \ellipsis 
                            j = i 
                            break
                        fa.push sf a
                        
                    for i from j + 1 til arr.length
                        a = arr[i]
                        la.push sf a

                    if arr[j].length == 0
                        ell = sf lits\*
                    else
                        ell = sf arr[j]0

                    return (v)->
                        e "Argument tuple length doesn't match" if v.length < arr.length - 1
                        fp = [fa[i](v[i]) for i til j]
                        lp = [la[i](v[i + v.length - arr.length + j + 1]) for i til arr.length - j - 1]
                        mp = [ell(v[i]) for i from j til v.length - arr.length + j + 1]
                        fp ++ mp ++ lp

                else
                    throw new Error 'An argument tuple can only hold at most one ellipsis'

        | \arrow =>
            u = []
            if arr.0? and arr.0.type in <[ tuple parenthesis ]>
                u = arr.0
            else if arr.0?
                u = [arr.0]

            a1 = arr.1
            base = (fun,g)->
                (...b)->
                    b = g b
                    #TODO (also in curry): cleaning may fail after an error in the return statement, so delay the error until after cleaning
                    try
                        r = sf a1, polymf-force <| fun.apply @, b #return value will get the dirty _temp_polym, to save asyncness of polymorphisms
                    catch
                        clean!
                        throw e
                    clean!
                    r

            switch arr.arrow-type
            | \--> \!--> => 
                if u.length > 1
                    u.type = \tuple 
                    arity = u.length
                    fs = [sf u[i], polymf-force for i til arity]
                    _curry-helper = (params)->
                        (fun)-> 
                            e "Not a Function" unless $typeof(fun) is \Function
                            (...args)->
                                if args.length is 0 #execute the curry
                                    for i til arity
                                        fs[i] params[i] #last check
                                    try
                                        r = sf a1, polymf-force <| fun.apply @ #return value will get the dirty _temp_polym, to save asyncness of polymorphisms
                                    catch
                                        clean!
                                        throw e
                                    clean!
                                    r
                                else #continue currying
                                    ps = params ++ args
                                    e 'Incorrect arity of curried arrow, received #{params.length} arguments and should be #{arity} arguments' if ps.length > arity
                                    if ps.length < arity  
                                        try
                                            narg = [fs[i] ps[i] for i til ps.length]
                                        catch 
                                            clean!
                                            throw e
                                        clean! #narg has checked polymorphisms again, so clean them in the arrow
                                        return ~> _curry-helper(ps)(fun.apply @, narg.slice params.length,ps.length) ...
                                    else
                                        try
                                            narg = [fs[i] ps[i] for i til ps.length]
                                            r = sf a1, polymf-force <| fun.apply @, narg.slice params.length,ps.length #return value will get the dirty _temp_polym, to save asyncness of polymorphisms
                                        catch
                                            clean!
                                            throw e
                                        clean!
                                        return r
                    if arr.arrow-type is \--> #only check arguments, but don't curry the function
                        return _curry-helper []
                    else #otherwise we do curry the function
                        return (fun)->
                            _curry-helper([])(curry$ fun)
                    break
                fallthrough
      
            | _ =>
                u.type = \argument-tuple
                g = sf u, polymf-force
                return (fun)-> 
                    e "Not a Function" unless $typeof(fun) is \Function
                    base fun,g


        | \or =>
            or-helper do 
                e
                sf arr.0
                sf arr.1

        | \and =>
            and-helper do 
                e
                sf arr.0
                sf arr.1

        | \modifier =>
            if arr.length == 1
                arr.1 = lits\*
            arr.0 sf(arr.1), e
                
        | \literal =>
            throw new Error "Can't process empty literals" if arr.length == 0
            a = arr.0
            if literals[a]?
                return sf that
            else
                for k,v of literals 
                    if /^\/([\s\S]*)\/([gimy]*)$/.exec k
                        r = new RegExp that.1, that.2
                        if that$ = r.exec a
                            vt = v that$
                            return sf if vt.length == 2 then ((err)-> (v)-> vt err,v) else vt 
                return -> if $typeof(it) is a then it else e "Not a#{if a.to-lower-case! in <[a e o u i]> then 'n' else ''} #a"

        # | \property \object-type => throw new Error "The type '#{arr.type}' should be parsed inside an object"
        # | \ellipsis => throw new Error "the type 'ellipsis' should be parsed inside an object or argument tuple"
        | \this-binding =>
            tf = sf arr.0
            cf = sf arr.1
            return (fun)->
                h = cf fun 
                (...b)-> h.apply tf(@), b

        | \string \number => 
            return -> if it is arr.0 then it else e "The #{arr.type} #{it} is unequal to #{arr.0}"

        | \polymorphism =>
            return (v)->
                if polymf arr.0, $typeof v
                    return v
                else
                    throw new Error "Polymorphism #{arr.type} can't match multiple types"

        | _ => throw new Error "Can't parse type #{arr.type} in this context"


    ((m,k,f)-->
        modes[m] = [] unless modes[m]?
        modes[m].push [k, f])

        .. \normal
            .. \( (arr,pos)-> arr.set [] .prop \type \parenthesis .prop \pos pos .up!
            .. \) (arr,pos)->
                do
                    go-down arr, pos + 1, <[ array object ]>
                while arr.prop(\type) not in <[ parenthesis tuple ]>
                yes
                
            .. \[ (arr,pos)-> arr.set [] .prop \type \array .prop \pos pos .up!
            .. \] (arr,pos)->
                do
                    go-down arr,pos + 1, <[ parenthesis tuple object ]>
                while arr.prop(\type) != \array
                yes

            .. \{ (arr,pos)->
                if arr.get!?
                    arr.wrap!prop \type \object .prop \mode \object .prop \pos pos .up!wrap!prop \type \object-type .right!
                else
                    arr.set [] .prop \type \object .prop \mode \object .prop \pos pos .up!
            .. \} (arr,pos)->
                do
                    go-down arr, pos + 1,<[ parenthesis tuple array ]>
                while arr.prop(\type) != \object
                yes
            .. \< (arr,pos)-> arr.set [] .prop \type \literal .prop \mode \literal .prop \pos pos .up!
            .. \, (arr, pos)->  
                while arr.parent-prop(\type) not in <[ parenthesis object tuple ]>
                    go-down arr, pos
                
                arr.parent-prop \type \tuple if arr.parent-prop(\type) is \parenthesis
                arr.right!
            .. \@ (arr,pos)-> #poop & lol @ haha -> wow     --->     poop & (lol @ (haha -> wow))
                arr.wrap!prop \type \this-binding .prop \pos pos .up!right!

            .. /(?:\!?\-)?\->/ (arr,mat,pos)->
                while arr.parent-prop(\type) in <[ modifier and or ]>
                    go-down arr, pos
                arr.wrap!prop \type \arrow  .prop \arrowType mat.0 .prop \pos pos .up!right!
            .. \| (arr,pos)->
                while arr.parent-prop(\type) is \modifier
                    go-down arr, pos
                arr.wrap!prop \type \or .prop \pos pos .up!right!
            .. \& (arr,pos)-> 
                while arr.parent-prop(\type) is \modifier
                    go-down arr, pos
                arr.wrap!prop \type \and .prop \pos pos .up!right!
            .. \" (arr,pos)-> arr.set [] .prop \type \string .prop \mode \string .prop \stringType \" .prop \pos pos .up!
            .. \' (arr,pos)-> arr.set [] .prop \type \string .prop \mode \string .prop \stringType \' .prop \pos pos .up!
            .. /\d+(?:\,\d+)?|\-?Infinity/ (arr,mat,pos)-> arr.set [+mat.0] .prop \type \number .prop \pos pos .prop \closePos pos + mat.0.length
            .. \... (arr,pos)-> arr.set [] .prop \type \ellipsis .prop \pos pos .up!
            .. /[a-z]\b/ (arr,mat,pos)-> arr.set [mat.0] .prop \type \polymorphism .prop \pos pos .prop \closeProp pos + 1
            .. [k for k of modifiers] (arr,val,pos)-> arr.set [] .prop \type \modifier .prop \pos pos .up!set modifiers[val] .right!
            .. \* (arr,pos)-> arr.set [\*] .prop \type \literal .prop \pos pos .prop \closePos pos + 1
            .. /[!\?$_\w]+\b/  (arr,val,pos)-> arr.set [val.0] .prop \type \literal .prop \pos pos .prop \closePos pos + val.0.length
            .. /#\w+\b/ (arr)-> arr
            .. /\/\*[\w\"!\?$_\'\s\r\n\*]*\*\// (arr)-> arr
            .. /[\s\S]/ (arr)->arr


        .. \object
            .. /\\(\:|\}|\,|\.\.\.)/ (arr,mat)-> arr.set <| (arr.get! || '') + mat.1
            .. \: (arr,pos)-> arr.wrap!prop \type \property .prop \mode \normal .prop \pos pos .up!right!
            .. \} (arr,pos)-> go-down arr, pos + 1, <[ parenthesis tuple array ]>
            .. \, (arr)-> arr.right!
            .. \... (arr,pos)-> arr.set [] .prop \type \ellipsis .prop \mode \normal .prop \pos pos .up!
            .. /[\r\n\t\s]/ (arr)->arr
            .. /[\s\S]/ (arr,mat) -> arr.set <| (arr.get! || '') + mat.0

        .. \string
            .. "\\\"" (arr)-> arr.set <| (arr.get! || '') + \"
            .. "\\'" (arr)-> arr.set <| (arr.get! || '') + \'
            .. \' (arr,pos)-> 
                if \' is arr.parent-prop \stringType 
                    go-down arr, pos + 1
                else 
                    no #ignore
            .. \" (arr,pos)-> 
                if \" is arr.parent-prop \stringType 
                    go-down arr, pos + 1
                else 
                    no #ignore
            .. /[\s\S]/ (arr,mat)-> arr.set <| (arr.get! || '') + mat.0

        .. \literal
            .. "\\>"    (arr)-> arr.set <| (arr.get! || '') + \>
            .. \>       (arr,pos)-> go-down arr, pos + 1
            .. /[\s\S]/ (arr,mat) -> arr.set <| (arr.get! || '') + mat.0

    mt = (custom-types)->
        if $typeof(custom-types) is \Array 
            for ct in custom-types
                literals := literals with process-custom-types ct 
        else
            literals := literals with process-custom-types custom-types
    
    mt custom-types

    OO = (str)->
        throw new Error "Cuffs Error - Cuffs requires the first argument to be a string" if $typeof(str) isnt \String  
        err = OOError str
        A = parse-to-array str 
        F = parse-to-function A, err
        if &length == 1
            return F
        else
            return F &1

    OO.version = version
    OO.modify-types = mt
    OO.use-proxies = _up

    OO


Cuffs.version = version
module.exports = Cuffs
