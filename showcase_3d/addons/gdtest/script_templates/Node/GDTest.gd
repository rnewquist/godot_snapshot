# meta-name: GDTest Suite
# meta-description: GDTest boilerplate template for unit and integration test suites
# meta-default: true

class_name _CLASS_
extends GDTestSuite

func _init() -> void:
	suite_name = "_CLASS_"
	test_type = "integration" # "unit", "integration"

func before_each() -> void:
	pass

func after_each() -> void:
	pass

func test_example() -> void:
	assert_true(true, "Starter assertion condition")
