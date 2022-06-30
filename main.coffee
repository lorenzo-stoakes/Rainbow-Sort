[rectWidth, rectHeight] = [20, 20]

UPDATE_INTERVAL = 5000

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
        sort_context ?=
                i: 1
                j: 1
                min: 0
                count: 0

        { i, j, count, min } = sort_context

        if j == colours.length
                swapRects(i-1, min)

                return if i == colours.length - 1

                sort_context.i++
                sort_context.min = sort_context.i - 1
                sort_context.j = sort_context.i
        else
                sort_context.min = j if colours[j].val < colours[min].val
                sort_context.j++

        sort_context.count++

        if (sort_context.count % UPDATE_INTERVAL) == 0
                defer(ssort)
        else
                ssort()

# Good old bubble sort
bsort = ->
        sort_context ?=
                swapped: false
                i: 1
                count: 0

        { swapped, i, count } = sort_context

        if i == colours.length
                sort_context.i = 1
                sort_context.swapped = false

                bsort() if swapped
                return

        if colours[i - 1].val > colours[i].val
                swapRects(i - 1, i)
                sort_context.swapped = true

        sort_context.i++
        sort_context.count++

        if (sort_context.count % UPDATE_INTERVAL) == 0
                defer(bsort)
        else
                bsort()

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
        sort_context ?=
                j: colours.length // 2 - 1
                last_j: colours.length // 2 - 1
                size: colours.length
                count: 0
                making_heap: true
                sifting_down: false

        { j, last_j, size, count, making_heap, sifting_down } = sort_context

        if making_heap or sifting_down
                left = j*2 + 1
                right = j*2 + 2
                largest = j
                largest = left if left < size and colours[left].val > colours[j].val
                largest = right if right < size and colours[right].val > colours[largest].val
                if j isnt largest
                        swapRects(j, largest)
                        sort_context.j = largest
                else if making_heap and last_j > 0 #last_j < size//2 - 1
                        #sort_context.j = last_j + 1
                        sort_context.j = last_j - 1
                        sort_context.last_j = sort_context.j
                else
                        sort_context.making_heap = false
                        sort_context.sifting_down = false
        else
                return if size == 0

                # Put largest block at end.
                swapRects(0, size - 1)

                # Now heapify the rest.
                sort_context.size--
                sort_context.sifting_down = true
                sort_context.j = 0

        sort_context.count++

        if (sort_context.count % UPDATE_INTERVAL) == 0
                defer(hsort)
        else
                hsort()


# Default to bubble sort
sort = bsort

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
