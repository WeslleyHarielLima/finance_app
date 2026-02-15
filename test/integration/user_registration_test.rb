require "test_helper"

class UserRegistrationTest < ActionDispatch::IntegrationTest
  test "user can visit registration page" do
    get new_user_registration_path
    assert_response :success
  end

  test "user can register with valid data" do
    assert_difference -> { User.count }, 1 do
      post user_registration_path, params: {
        user: {
          name: "Novo Usuario",
          email: "novo@teste.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
  end

  test "user cannot register without name" do
    assert_no_difference -> { User.count } do
      post user_registration_path, params: {
        user: {
          name: "",
          email: "novo@teste.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
  end

  test "user can sign in with valid credentials" do
    user = create(:user)
    sign_in(user)
    assert_response :redirect
  end

  test "user can sign out" do
    user = create(:user)
    sign_in(user)
    delete destroy_user_session_path
    assert_response :redirect
  end
end
