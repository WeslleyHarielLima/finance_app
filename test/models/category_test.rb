require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "belongs to user" do
    category = build(:category, user: nil)
    assert_not category.valid?
  end

  test "has many financial_entries with nullify" do
    user = create(:user)
    category = create(:category, user: user)
    entry = create(:financial_entry, user: user, category: category)

    category.destroy
    entry.reload
    assert_nil entry.category_id
  end

  test "requires name" do
    category = build(:category, name: nil)
    assert_not category.valid?
  end

  test "requires color" do
    category = build(:category, color: nil)
    assert_not category.valid?
  end

  test "requires icon" do
    category = build(:category, icon: nil)
    assert_not category.valid?
  end

  test "name must be unique per user" do
    user = create(:user)
    create(:category, user: user, name: "Alimentacao")

    duplicate = build(:category, user: user, name: "Alimentacao")
    assert_not duplicate.valid?
  end

  test "different users can have same category name" do
    user1 = create(:user)
    user2 = create(:user)

    create(:category, user: user1, name: "Alimentacao")
    cat2 = build(:category, user: user2, name: "Alimentacao")

    assert cat2.valid?
  end
end
