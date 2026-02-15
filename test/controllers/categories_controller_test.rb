require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
  end

  test "unauthenticated user is redirected" do
    delete destroy_user_session_path
    get categories_path
    assert_response :redirect
  end

  test "index lists user categories" do
    create(:category, user: @user, name: "Alimentacao")
    get categories_path
    assert_response :success
    assert_match "Alimentacao", response.body
  end

  test "create category with valid params" do
    assert_difference -> { @user.categories.count }, 1 do
      post categories_path, params: {
        category: { name: "Transporte", color: "#ff0000", icon: "🚗" }
      }
    end
    assert_redirected_to categories_path
  end

  test "create category with invalid params" do
    post categories_path, params: {
      category: { name: "", color: "", icon: "" }
    }
    assert_response :unprocessable_entity
  end

  test "update category" do
    category = create(:category, user: @user)
    patch category_path(category), params: {
      category: { name: "Nova Nome" }
    }
    assert_redirected_to categories_path
    assert_equal "Nova Nome", category.reload.name
  end

  test "cannot delete category with entries" do
    category = create(:category, user: @user)
    create(:financial_entry, user: @user, category: category)

    delete category_path(category)
    assert_redirected_to categories_path
    assert Category.exists?(category.id)
  end

  test "can delete category without entries" do
    category = create(:category, user: @user)
    assert_difference -> { @user.categories.count }, -1 do
      delete category_path(category)
    end
  end
end
