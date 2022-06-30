[rectWidth, rectHeight] = [32, 32]

UPDATE_INTERVAL = 1250

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

        { i, j, min } = sort_context

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

        { swapped, i } = sort_context

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
        sort_context ?=
                median_stack: []
                in_partition: false
                pivot_ind: -1
                pivot_val: -1
                started_tukey_median: false
                started_partition: false

                from_stack: []
                to_stack: []

                from: 0
                to: colours.length - 1
                curr: 0

                count: 0

        { median_stack, in_partition, pivot_ind, pivot_val, started_tukey_median, from_stack, to_stack, from, to, curr, started_partition } = sort_context

        do_next = ->
                sort_context.count++

                if (sort_context.count % UPDATE_INTERVAL) == 0
                        defer(-> qsort(tukey))
                else
                        qsort(tukey)

        if median_stack.length > 0
                [ a, b, c, swap_count ] = median_stack[median_stack.length - 1]

                # Rename vars for clarity, as we want the median in a, not b.
                m0 = b
                m1 = a
                m2 = c

                if swap_count == 0
                        if colours[m1].val < colours[m0].val
                                swapRects(m1, m0)
                                # Increment count.
                                sort_context.median_stack[median_stack.length - 1][3]++
                        else
                                swap_count++

                if swap_count == 1
                        if colours[m2].val < colours[m1].val
                                swapRects(m2, m1)
                                # Increment count.
                                sort_context.median_stack[median_stack.length - 1][3]++
                        else
                                swap_count++

                if swap_count == 2
                        if colours[m1].val < colours[m0].val
                                swapRects(m1, m0)
                        else
                                swap_count++

                sort_context.median_stack.pop() if swap_count >= 2

                sort_context.count-- if swap_count > 2 # If we didn't swap then doesn't count
                do_next()
                return

        if in_partition
                # We would have swapped pivot to end at start.
                while curr < to
                        if colours[curr].val <= pivot_val
                                swapRects(curr, pivot_ind)

                                sort_context.curr++
                                sort_context.pivot_ind++
                                do_next()
                                return

                        sort_context.curr++
                        curr = sort_context.curr

                # End of partition.
                sort_context.in_partition = false
                # Swap 'em back.
                swapRects(pivot_ind, to)
                do_next()
                return

        # OK we are out of the partition we are at the top level sort.

        # If we're done on this line then pop stack on next.
        if from >= to
                return if from_stack.length == 0

                sort_context.from = sort_context.from_stack.pop()
                sort_context.to = sort_context.to_stack.pop()
                sort_context.curr = sort_context.from
                sort_context.pivot_ind = -1

                sort_context.count-- # Shouldn't count towards swaps.
                do_next()
                return

        # Do we need to figure out the pivot index?
        if pivot_ind == -1
                mid = Math.floor(from + (to - from)/2)

                # Easy option first.
                if not tukey
                        # Do it this way to avoid overflow.
                        sort_context.pivot_ind = mid
                        pivot_ind = mid
                else if started_tukey_median
                        # Completed tukey median calculation.
                        sort_context.pivot_ind = from
                        pivot_ind = from
                        sort_context.started_tukey_median = false
                else
                        # OK kick off tukey median calculation.
                        sort_context.started_tukey_median = true

                        stack = []
                        # We do this last as stack so reverse order.
                        stack.push([from, mid, to - 1, 0])

                        if to - from > 40
                                s = Math.floor((to - from)/8)

                                # reverse order as stack.
                                stack.push([to - 1, to - 1 - s, to - 1 - 2 * s, 0])
                                stack.push([mid, mid - s, mid + s, 0])
                                stack.push([from, from + s, from + 2 * s, 0])

                        sort_context.median_stack = stack

                        # Handle this on next invocation.
                        sort_context.count-- # Shouldn't count towards swaps.
                        do_next()
                        return

        # OK we have a pivot index.

        # Did we start the partition?
        if not started_partition
                sort_context.started_partition = true
                sort_context.in_partition = true
                sort_context.curr = from

                sort_context.pivot_val = colours[pivot_ind].val

                # Put pivot at the end of the array.
                swapRects(pivot_ind, to)
                sort_context.pivot_ind = from

                # Handle this on next invocation.
                do_next()
                return

        # OK partition is done.
        sort_context.started_partition = false

        # Do lower half first, then push next on stack.
        sort_context.to = pivot_ind - 1
        sort_context.pivot_ind = -1
        sort_context.from_stack.push(pivot_ind + 1)
        sort_context.to_stack.push(to)

        # Handle this on next invocation.
        sort_context.count-- # Shouldn't count towards swaps.
        do_next()

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
