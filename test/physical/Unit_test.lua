package.path = './lib/?/init.lua;./lib/?.lua;'..package.path
local physical = require 'physical'
local osmose = require 'osmose'
local lut    = require 'lut'

local should = lut.Test 'physical.Unit'

function should.createUnit()
	local u = physical.Unit(10,'kg')
	assertEqual(10, u.value)
	assertEqual('kg', u.unit)
end

function should.forceValueToNumber()
	local u = physical.Unit('10.01','kg')
	assertEqual(10.01, u.value)
end

function should.beTypeOfPhysicalUnit()
	local u = physical.Unit(10,'kg')
	assertEqual('PhysicalUnit', u.type)
end

function should.print()
	local u = physical.Unit(10,'kg')
	assertEqual("10.00 kg", tostring(u))
end

function should.add2Units()
	local u1 = physical.Unit(10,'kg')
	local u2 = physical.Unit(20,'kg')
	local u = u1+u2
	assertEqual('PhysicalUnit',u.type)
	assertEqual(30, u.value)
end

function should.notAddUnitsIfValuesAreNotTheSame()
	local u1 = physical.Unit(10,'kg')
	local u2 = physical.Unit(20,'°C')
	local u = u1+u2
	assertEqual(nil, u)
end

function should.multiplyDifferentUnit()
	local u1 = physical.Unit(10,'kg')
	local u2 = physical.Unit(20,'°C')
	local u = u1*u2
	assertEqual(200, u())
	assertEqual("kg*°C", u.unit)
end

function should.substract2Units()
	local u1 = physical.Unit(10,'kg')
	local u2 = physical.Unit(20,'kg')
	local u = u1-u2
	assertEqual('PhysicalUnit',u.type)
	assertEqual(-10, u.value)
end

function should.multiply2Units()
	local u1 = physical.Unit(10,'kg')
	local u2 = physical.Unit(20,'kg')
	local u = u1*u2
	assertEqual('PhysicalUnit',u.type)
	assertEqual(10*20, u.value)
end

function should.divisize2Units()
	local u1 = physical.Unit(10,'kg')
	local u2 = physical.Unit(20,'kg')
	local u = u1/u2
	assertEqual('PhysicalUnit',u.type)
	assertEqual(10/20, u.value)
end

function should.givePower()
	local u1 = physical.Unit(10,'kg')
	local u2 = physical.Unit(20,'kg')
	local u = u1^u2
	assertEqual('PhysicalUnit',u.type)
	assertEqual(10^20, u.value)
end

function should.giveModulo()
	local u1 = physical.Unit(10,'kg')
	local u2 = physical.Unit(20,'kg')
	local u = u1%u2
	assertEqual('PhysicalUnit',u.type)
	assertEqual(10%20, u.value)
end

function should.returnNegation()
	local u1 = physical.Unit(10,'kg')
	local u = -u1
	assertEqual('PhysicalUnit',u.type)
	assertEqual(-10, u.value)
end

function should.testEquality()
	local u1 = physical.Unit(10,'kg')
	local u2 = physical.Unit(10,'kg')
	assertTrue(u1==u2)
end

function should.testLessThan()
	local u1 = physical.Unit(10,'kg')
	local u2 = physical.Unit(20,'kg')
	assertTrue(u1<u2)
end

function should.testLessOrEqualThan()
	local u1 = physical.Unit(10,'kg')
	local u2 = physical.Unit(10,'kg')
	assertTrue(u1<=u2)
end

function should.call()
	local u1 = physical.Unit(10,'kg')
	assertValueEqual(10,u1())
end

function should.loadConversionFile()
	local conv = physical.Unit.loadConversion()
	assertEqual(1853.7936, conv.mile.mult())
end

function should.convertMeterToMeter()
	local u1 = physical.Unit(10,'meter')
	local u = u1:convert('meter')
	assertValueEqual(10, u.value)
end

function should.convertFootToMeter()
	local u1 = physical.Unit(10,'foot')
	local u = u1:convert('meter')
	assertValueEqual(3.0480061, u.value, 0.0001)
end

function should.convertFootToYard()
	local u1 = physical.Unit(10,'foot')
	local u = u1:convert('yard')
	assertValueEqual(3.3333, u.value,0.0001)
end

function should.convertMeterToYard()
	local u1 = physical.Unit(10,'meter')
	local u = u1:convert('yard')
	assertValueEqual(10.936133, u.value,0.0001)
end

function should.convertGrToKg()
	local u1 = physical.Unit(1000,'gr')
	local u = u1:convert('kg')
	assertValueEqual(1, u.value)
end

function should.concertRelativeUnit()
	local u1 = physical.Unit(1,'ounce')
	local u  = u1:convert('gr')
	assertValueEqual(28, u.value)
end

function should.convertKelvinToCelcius()
	local u1 = physical.Unit(273.15,'K')
	local u  = u1:convert('°C')
	assertEqual(0, u.value)
end

function should.convertCelciusToKelvin()
	local u1 = physical.Unit(0,'°C')
	local u  = u1:convert('K')
	assertEqual(273.15,u.value)
end

function should.convertKelvinToFahrenheit()
	local u1 = physical.Unit(400,'K')
	local u  = u1:convert('°F')
	assertValueEqual(260.33, u.value,0.0001)
end

function should.convertFahrenheitToKelvin()
	local u1 = physical.Unit(50,'°F')
	local u  = u1:convert('K')
	assertValueEqual(283.15, u.value,0.0001)
end

function should.convertCelciusToFahrenheit()
	local u1 = physical.Unit(30,'°C')
	local u  = u1:convert('°F')
	assertValueEqual(86,u.value, 0.0001)
end

function should.convertFahrenheitToCelcius()
	local u1 = physical.Unit(86,'°F')
	local u  = u1:convert('°C')
	assertValueEqual(30, u.value, 0.0001)
	assertEqual('°C', u.unit)
end

function should.addConvertBeforeAdd()
	local u1 = physical.Unit(1,'kg')
	local u2 = physical.Unit(500,'gr')
	local u  = u1+u2
	assertEqual('kg', u.unit)
	assertValueEqual(1.5, u.value)
end

function should.convertEnergy()
	local u1 = physical.Unit(1,'cal')
	local u  = u1:convert('J')
	assertEqual(4.1868, u.value, 0.0001)
end

function should.convertPressure()
	local u1 = physical.Unit(1,'bar')
	local u  = u1:convert('Pa')
	assertEqual(100000, u.value, 0.0001)
end

function should.convertSpeed()
	local u1 = physical.Unit(1,'km/h')
	local u  = u1:convert('m/s')
	assertEqual(0.27777777777778, u.value, 0.0001)
end

function should.convertMassFlowRate()
	local u1 = physical.Unit(1,'kg/s')
	local u = u1:convert('t/h')
	assertEqual(3600, u.value, 0.0001)
end

function should.addNumber()
	local u1 = physical.Unit(10,'m')
	local u = u1+10
	assertValueEqual(20, u())
	assertValueEqual('m', u.unit)
end

function should.substractNumber()
	local u1 = physical.Unit(10,'m')
	local u = u1-5
	assertValueEqual(5, u())
	assertValueEqual('m', u.unit)
end

should:test()