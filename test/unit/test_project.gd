extends GutTest

var project: Project
var width: int = 200
var height: int = 300


func before_each():
	project = Project.new()
	project.new_project(width, height)


func test_project_creation():
	assert_not_null(project, "Project existence")


func test_current_page():
	var page = project.get_current_page()
	assert_not_null(page, "Page existence")

	var img = page.get_content()
	assert_eq(img[0].get_width(), width, "Width equal")
	assert_eq(img[0].get_height(), height, "Height equal")


func test_distant_page_forward():
	project.next_page(false)
	project.prev_page()
	var page = project.get_distant_page(1)
	assert_not_null(page, "Distant page existance")

	var far_page = project.get_distant_page(2)
	assert_null(far_page)


func test_distant_page_backward():
	project.next_page(false)
	var page = project.get_distant_page(-1)
	assert_not_null(page, "Distant page existance")

	var far_page = project.get_distant_page(-2)
	assert_null(far_page)

func test_undo_edit():
	var page = project.get_current_page()
	var edit = project.start_edit()
	var layer = page.layers[project.current_layer]
	layer.set_pixel(0, 0, Color.RED)
	page.set_layer(project.current_layer, layer)
	project.commit_edit(edit, "Paint")
	assert_eq(page.layers[project.current_layer].get_pixel(0, 0), Color.RED)
	assert_true(project.can_undo())
	project.undo()
	assert_eq(page.layers[project.current_layer].get_pixel(0, 0), Color.TRANSPARENT)

func test_max_undos():
	var page = project.get_current_page()
	for i in range(Project.MAX_UNDOS+1):
		var edit = project.start_edit()
		var layer = page.layers[project.current_layer]
		layer.set_pixel(0, 0, Color(float(i + 1) / 255.0, 0, 0, 1))
		page.set_layer(project.current_layer, layer)
		project.commit_edit(edit, "Paint")
	for j in range(Project.MAX_UNDOS):
		project.undo()
	assert_false(project.can_undo(), "Only the most recent 20 edits should be undoable")
