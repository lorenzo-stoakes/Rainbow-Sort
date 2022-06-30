[rectWidth, rectHeight] = [60, 60]

UPDATE_INTERVAL = 1000

# Initialised by reset().
checkDoneInterval = null
colours = null
context = null
height = null
start = null
width = null

sort_context = null

# We set this after document is ready.
canvas = null

timeouts = []
defer = (fn) ->
        timeouts.push(window.setTimeout(fn, 0))

toHslString = (h) ->
        # Firefox doesn't like a semicolon here. Go figure!
        "hsl(#{h}, 100%, 50%)"

initColours = ->
        for x in [0...width] by rectWidth
                for y in [0...height] by rectHeight
                        val = Math.random()
                        hue = Math.floor(256*val)
                        colours.push({ val: val, hue: hue, x: x, y: y })

                        context.fillStyle = toHslString(hue)
                        context.fillRect(x, y, rectWidth, rectHeight)

checkDone = ->
        for i in [1...colours.length]
                return if colours[i - 1].val > colours[i].val

        end = Date.now()
        window.clearInterval(checkDoneInterval)

        ms = end - start

        $('#algoName').html($('#algo').val())
        $('#ms').html(ms)

reset = ->
        window.clearInterval(checkDoneInterval) if checkDoneInterval?
        window.clearTimeout(timeout) while (timeout = timeouts.pop())

        colours = []
        win = $(document)
        [width, height] = [$(document).width(), $(document).height()]

        canvas.attr('width', width)
        canvas.attr('height', height)

        context = canvas[0].getContext('2d')

        start = Date.now()

        initColours()
        sort_context = null
        defer(sort)

        checkDoneInterval = window.setInterval(checkDone, 10)

swapRects = (ind1, ind2) ->
        val1 = colours[ind1]
        val2 = colours[ind2]

        swap = (field) ->
                tmp = val1[field]
                val1[field] = val2[field]
                val2[field] = tmp

        swap('val')
        swap('hue')

        context.fillStyle = toHslString(val1.hue)
        context.fillRect(val1.x, val1.y, rectWidth, rectHeight)

        context.fillStyle = toHslString(val2.hue)
        context.fillRect(val2.x, val2.y, rectWidth, rectHeight)

isort = ->
        sort_context ?=
                   i: 1
                   j: 1
                   count: 0

        { i, j, count } = sort_context

        swapRects(j - 1, j) if colours[j - 1].val > colours[j].val

        if j == 1
                return if i == colours.length - 1
                sort_context.i++
                sort_context.j = sort_context.i
        else
                sort_context.j--

        sort_context.count++

        if (sort_context.count % UPDATE_INTERVAL) == 0
                defer(isort)
        else
                isort()

# Selection sort
# @author Bernhard Häussner (https://github.com/bxt)
ssort = ->
        min = index-1
        for j in [index...colours.length]
                min = j if colours[j].val < colours[min].val

        swapRects(index-1, min)

        index++
        defer(ssort) if index < colours.length

bsort = ->
        swapped = false
        for i in [1...colours.length]
                if colours[i - 1].val > colours[i].val
                        swapRects(i - 1, i)
                        swapped = true

        defer(bsort) if swapped

qsort = (tukey) ->
        # Put the median of colours.val's in colours[a].
        # Shamelessly stolen from Go's quicksort implementation.
        # See http://golang.org/src/pkg/sort/sort.go
        medianOfThree = (a, b, c) ->
                # Rename vars for clarity, as we want the median in a, not b.
                m0 = b
                m1 = a
                m2 = c

                # Bubble sort on colours[m0,m1,m2].val
                swapRects(m1, m0) if colours[m1].val < colours[m0].val
                swapRects(m2, m1) if colours[m2].val < colours[m1].val
                swapRects(m1, m0) if colours[m1].val < colours[m0].val

                # Now colours[m0].val <= colours[m1].val <= colours[m2].val

        getPivotInd = (from, to) ->
                # Do it this way to avoid overflow.
                mid = Math.floor(from + (to - from)/2)

                return mid if !tukey

                # Using Tukey's 'median of medians'
                # See http://www.johndcook.com/blog/2009/06/23/tukey-median-ninther/
                if to - from > 40
                        s = Math.floor((to - from)/8)
                        medianOfThree(from, from + s, from + 2 * s)
                        medianOfThree(mid, mid - s, mid + s)
                        medianOfThree(to - 1, to - 1 - s, to - 1 - 2 * s)

                medianOfThree(from, mid, to - 1)

                # We've put the median in from.
                return from

        partition = (from, to, pivotInd) ->
                pivot = colours[pivotInd].val
                # Put pivot at end for now.
                swapRects(pivotInd, to)

                pivotInd = from
                for i in [from...to]
                        if colours[i].val <= pivot
                                swapRects(i, pivotInd)
                                pivotInd++

                # Swap 'em back.
                swapRects(pivotInd, to)

                return pivotInd

        doQsort = (from, to) ->
                return if from >= to

                pivotInd = getPivotInd(from, to)
                pivotInd = partition(from, to, pivotInd)

                defer(->
                        doQsort(from, pivotInd - 1)
                        doQsort(pivotInd + 1, to)
                )

        doQsort(0, colours.length - 1)

# Heapsort
# Based on this Java implementation: http://git.io/heapsort
# @author Bernhard Häussner (https://github.com/bxt)
hsort = ->
        # Let the browser render between steps using a call stack
        stack = []
        work = ->
                if stack.length
                        stack.pop()() # execute stack top
                        defer(work) # loop

        size = colours.length

        # Make branch from i downwards a proper max heap
        maxHeapify = (i) ->
                left = i*2 + 1
                right = i*2 + 2
                largest = i
                largest = left if left < size and colours[left].val > colours[i].val
                largest = right if right < size and colours[right].val > colours[largest].val
                if i isnt largest
                        swapRects(i, largest)
                        maxHeapify(largest)
                        #stack.push(-> maxHeapify(largest))

        # Remove the top of the heap and move it behind the heap
        popMaxValue = ->
                size--
                swapRects(0, size)
                maxHeapify(0) if size > 0

        # Fill the call stack (reverse order)
        for i in [size-1 ... 0]
                stack.push(popMaxValue)
        for i in [0 .. size//2 - 1]
                do (i) ->
                        stack.push(-> maxHeapify(i))

        do work

# Default to insertion sort.
sort = isort

$(document).ready(->
        canvas = $('#mainCanvas')
        $('#squareSize').val(rectWidth)

        window.onresize = -> reset()

        $('#algo').change(->
                selected = $('#algo').val()

                sort =
                        switch $(@).children(':selected').attr('id')
                                when 'bsort'  then bsort
                                when 'isort'  then isort
                                when 'qsort1' then -> qsort(false)
                                when 'qsort2' then -> qsort(true)
                                when 'hsort' then hsort
                                when 'ssort' then ssort

                reset()
        )

        $('#squareSize').change(->
                n = parseInt($('#squareSize').val(), 10)
                return if isNaN(n)

                rectWidth = rectHeight = n
                reset()
        )

        $('#reset').click(-> reset())

        reset()
)
