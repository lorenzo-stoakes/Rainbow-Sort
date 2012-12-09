[rectWidth, rectHeight] = [10, 10]

# Initialised by reset().
width = null
height = null
index = null
context = null
colours = null

# We set this after document is ready.
canvas = null

timeouts = []
defer = (fn) ->
	timeouts.push(window.setTimeout(fn, 0))

toHslString = (h) -> "hsl(#{h}, 100%, 50%);"

initColours = ->
	for x in [0...width] by rectWidth
		for y in [0...height] by rectHeight
			val = Math.random()
			hue = Math.floor(256*val)
			colours.push({ val: val, hue: hue, x: x, y: y })

			context.fillStyle = toHslString(hue)
			context.fillRect(x, y, rectWidth, rectHeight)

reset = ->
	window.clearTimeout(timeout) while (timeout = timeouts.pop())

	colours = []
	index = 1
	win = $(document)
	[width, height] = [$(document).width(), $(document).height()]

	canvas.attr('width', width)
	canvas.attr('height', height)

	context = canvas[0].getContext('2d')

	initColours()
	defer(sort)

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
	for j in [index...0]
		swapRects(j - 1, j) if colours[j - 1].val > colours[j].val

	index++
	defer(isort) if index < colours.length

qsort = ->
	getPivotInd = (from, to) ->
		# Middle for now. Do it this way to avoid overflow.
		return Math.floor(from + (to - from)/2)

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

# Default to insertion sort.
sort = isort

$(document).ready(->
	canvas = $('#mainCanvas')
	$('#squareSize').val(rectWidth)

	window.onresize = -> reset()

	$('#algo').change(->
		selected = $('#algo').val()

		sort =
			switch selected
				when 'Insertion Sort' then isort
				when 'Quick Sort'     then qsort

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
