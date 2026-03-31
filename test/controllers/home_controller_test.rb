require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url

    assert_response :success
    assert_select "h1", "MyDinnerTime"
    assert_select "button", "Search Recipe"
  end

  test "should keep searched ingredients in tags" do
    get root_url, params: { ingredients: ["tomate", "manjericao"] }

    assert_response :success
    assert_includes @response.body, "tomate"
    assert_includes @response.body, "manjericao"
  end

  test "should ignore ingredients shorter than three characters" do
    get root_url, params: { ingredients: ["to", "egg"] }

    assert_response :success
    assert_not_includes @response.body, 'value="to"'
    assert_includes @response.body, 'value="egg"'
  end

  test "should keep deselected ingredients after search" do
    get root_url, params: { ingredients: ["tomato", "garlic"], ingredient_selected: ["true", "false"] }

    assert_response :success
    assert_includes @response.body, '"name":"tomato","selected":true'
    assert_includes @response.body, '"name":"garlic","selected":false'
  end

  test "should render ranked recipe cards" do
    get root_url, params: {
      ingredients: ["tomato", "garlic", "chicken"],
      ingredient_selected: ["true", "true", "true"]
    }

    assert_response :success
    assert_select ".recipe-card", 3
    assert_select ".recipe-image", 3
    assert_select ".recipe-badge", text: /Rating/

    titles = css_select(".recipe-card h3").map(&:text)
    assert_equal ["Tomato Soup", "Garlic Chicken Skillet", "Tomato Garlic Pasta"], titles
  end
end
