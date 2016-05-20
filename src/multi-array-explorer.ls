class exports.MultiArrayExplorer
    (@arr = [],@index = [])->

    up: (i = 0)-> @index ++= [i]; @
    down: ->
        @index .= slice 0, -1
        if @index.length == 0
            throw new Error "Can't go further down in the structure"
        @
    left: -> @index[*-1] -= 1; @
    right: -> @index[*-1] += 1; @
    get: -> 
        a = @arr
        for i in @index
            a = a[i]
            return void unless a?
        return a 

    set: (o)->
        a = @arr 
        for i in @index.slice 0,-1
            a = a[i]
        a[@index[*-1]] = o
        @

    wrap: ->
        a = @arr 
        for i in @index.slice 0,-1
            a = a[i]
        a[@index[*-1]] = [a[@index[*-1]]]
        @

    prop: (key,value)->
        a = @arr 
        for i in @index
            a = a[i]
        if value?
            a[key] = value 
            @
        else
            if a? then a[key] else a

    parent-prop: (key,value)->
        a = @arr 
        for i in @index.slice 0,-1
            a = a[i]
        if value?
            a[key] = value 
            @
        else
            if a? then a[key] else a

    get-inherited-prop: (key)->
        a = @arr
        p = null
        for i in @index
            p = a[key] if a? and a[key]?
            a = a[i]
        p = a[key] if a? and a[key]?
        return p

    get-inherited-parent-prop: (key)->
        a = @arr
        p = null
        for i in @index.slice 0, -1
            p = a[key] if a? and a[key]?
            a = a[i]
        p = a[key] if a? and a[key]?
        return p