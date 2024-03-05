-- general math utilities

function clamp(value, minimum, maximum)
	value = min(value, maximum)
	value = max(value, minimum)
	return value
end

function lerp(a,b,t) 
	return a+(b-a)*t 
end

function rndrange(low, high)
	return (low + rnd(high - low))
end

-- split a string into sub-strings separated by | and then into arrays
function split2d(text)
	local myarray = split(text, "|")
	for i = 1, #myarray do
		myarray[i] = split(myarray[i], ",")
	end
	return myarray
end