require 'test_helper'

class AdminControllerTest < ActionController::TestCase

  setup do
    # login admin for all tests of admin functions
    sign_in users(:admin)
    @request.headers['Accepts'] = 'text/javascript, application/javascript, application/ecmascript, application/x-ecmascript'
    set_default_settings
  end

  ### Topic Views

  test 'an admin should be able to see a list of topics via standard request' do
    get :tickets, { status: 'open' }
    assert_not_nil assigns(:topics)
    assert_template 'tickets'
    assert_response :success
  end

  test 'an admin should be able to see a list of topics via ajax' do
    xhr :get, :tickets, { status: 'open' }, format: :js
    assert_not_nil assigns(:topics)
    assert_template 'tickets'
    assert_response :success
  end

  test 'an admin should be able to see a specific topic of each type via standard request' do
    [3,7].each do |topic_id|
      get :ticket, { id: topic_id }
      assert_not_nil assigns(:topic)
      assert_template 'ticket'
      assert_response :success
    end
  end

  test 'an admin should be able to see a specific topic of each type via ajax' do
    [3,7].each do |topic_id|
      xhr :get, :ticket, { id: topic_id }
      assert_not_nil assigns(:topic)
      assert_template 'ticket'
      assert_response :success
    end
  end

  ### Testing User Views

  test 'an admin should be able to see a user profile' do
    xhr :get, :user_profile, { id: 2 }
    assert_response :success
    assert_equal(6, assigns(:topics).count)
  end

  test 'an admin should be able to edit a user profile' do
    xhr :get, :edit_user, { id: 2 }
    assert_response :success
  end


  ### Assigning topic tests

  test 'an admin should be able to assign an unassigned discussion' do
    assert_difference 'Post.count', 1 do
      xhr :get, :assign_agent, { topic_ids: [1], assigned_user_id: 1 }
    end
    assert_response :success
  end

  test 'an admin should be able to assign a previously assigned discussion' do
    assert_difference 'Post.count', 1 do
      xhr :get, :assign_agent, { topic_ids: [3], assigned_user_id: 1 }
    end
    assert_response :success
  end

  test 'an admin should be able to assign multiple tickets' do
    assert_difference 'Post.count', 2 do
      xhr :get, :assign_agent, { topic_ids: [3,2], assigned_user_id: 1 }
    end
    assert_response :success
  end

  test 'an admin assigning a discussion to a different agent should create a note' do
    assert_difference 'Post.count', 1 do
      xhr :get, :assign_agent, { assigned_user_id: 1, topic_ids: [1] }
    end
    assert_response :success
  end


  ### tests of changing status

  test 'an admin posting an internal note should not change status on its own' do

  end

  test 'an admin should be able to change an open ticket to closed' do
    assert_difference('Post.count') do
      xhr :get, :update_ticket, { topic_ids: [2], change_status: 'closed' }
    end
    assert_response :success
  end

  test 'an admin should be able to change a closed ticket to open' do
    assert_difference('Post.count') do
      xhr :get, :update_ticket, { topic_ids: [3], change_status: 'reopen' }
    end
    assert_response :success
    assert_template layout: nil
  end

  test 'an admin should be able to change an open ticket to spam' do
    xhr :get, :update_ticket, { topic_ids: [2], change_status: 'spam' }
    assert_response :success
    assert_template layout: nil
  end

  test 'an admin should be able to change the status of multiple topics at once' do
    assert_difference('Post.count',2) do
      xhr :get, :update_ticket, { topic_ids: [2,3], change_status: 'closed' }
    end
    assert_response :success
  end

  ### testing new discussion creation and lifecycle

  test 'an admin should be able to open a new discussion for a new user' do
    xhr :get, :new_ticket
    assert_response :success
  end


  test 'an admin should be able to create a new private discussion for a new user' do
    assert_difference 'Topic.count', 1 do
      assert_difference 'Post.count', 1 do
        assert_difference 'User.count', 1 do
          assert_difference 'ActionMailer::Base.deliveries.size', 1 do
            xhr :post, :create_ticket, topic: { user: { name: 'a user', email: 'anon@test.com' }, name: 'some new private topic', body: 'some body text', forum_id: 1 }, post: { body: 'this is the body' }
          end
        end
      end
    end
  end

  test 'an admin should be able to create a new private discussion for an existing user' do
    assert_difference 'Topic.count', 1 do
      assert_difference 'Post.count', 1 do
        assert_no_difference 'User.count' do
          assert_difference 'ActionMailer::Base.deliveries.size', 1 do
            xhr :post, :create_ticket, topic: { user: { name: 'Scott Smith', email: 'scott.smith@test.com' }, name: 'some new private topic', body: 'some body text', forum_id: 1 }, post: { body: 'this is the body' }
          end
        end
      end
    end
  end

  test 'an admin viewing a new discussion should change the status to PENDING' do
    @ticket = Topic.find(6)

    xhr :get, :ticket, { id: @ticket.id }

    #reload object:
    @ticket = Topic.find(6)
    assert @ticket.current_status == 'pending', 'ticket status did not change to pending'
  end

  # User/Admin reply tests are in posts_controller_test

  test 'a user replying to a discussion should change the status to PENDING' do
    @ticket = Topic.find(6)


  end

  test 'an admin replying to a discussion should change the status to OPEN' do

  end

  ### Test search function

  test 'an admin should be able to search by topic ID by ajax' do
    xhr :get, :topic_search, q: '1'
    assert_not_nil assigns(:topics)
    assert_response :success
  end

  test 'an admin should be able to search by user name by ajax' do
    xhr :get, :topic_search, q: 'Admin User'
    assert_not_nil assigns(:user)
    assert_response :success
  end

  test 'an admin should be able to search by subject by ajax' do
    xhr :get, :topic_search, q: 'Pending private topic'
    assert_not_nil assigns(:topics)
    assert_response :success
  end

  test 'an admin should be able to search for users with multiple matches via ajax' do
    xhr :get, :topic_search, q: 'scott'
    assert_nil assigns(:topics)
    assert_not_nil assigns(:users)
    assert_equal(3, assigns(:users).size)
    assert_response :success
  end

  test 'an admin should be able to search by topic ID' do
    get :topic_search, q: '1'
    assert_not_nil assigns(:topics)
    assert_response :success
  end

  test 'an admin should be able to search by user name' do
    get :topic_search, q: 'Admin User'
    assert_not_nil assigns(:user)
    assert_response :success
  end

  test 'an admin should be able to search by subject' do
    get :topic_search, q: 'Pending private topic'
    assert_not_nil assigns(:topics)
    assert_response :success
  end

  test 'an admin should be able to search for users with multiple matches' do
    get :topic_search, q: 'scott'
    assert_nil assigns(:topics)
    assert_not_nil assigns(:users)
    assert_equal(3, assigns(:users).size)
    assert_response :success
  end

  test 'an admin should be able to reorder docs' do
    post :update_order, object: 'doc', obj_id: 4, row_order_position: 0
    assert_equal Doc.order('rank asc').first.id, 4
  end

  test 'an admin should be able to reorder categories' do
    post :update_order, object: 'category', obj_id: 4, row_order_position: 0
    assert_equal Category.order('rank asc').first.id, 4
  end

  # Settings Panel

  test 'an admin should be able to load the settings' do
    get :settings
    assert_response :success
  end

  test 'an admin should be able to modify settings' do
    put :update_settings,
      'settings.site_name' => 'Helpy Support 2',
      'settings.parent_site' => 'http://helpy.io/2',
      'settings.parent_company' => 'Helpy 2',
      'settings.site_tagline' => 'Support',
      'settings.google_analytics_id' => 'UA-0000-21'
    assert_redirected_to :admin_settings
    assert_equal 'Helpy Support 2', AppSettings['settings.site_name']
    assert_equal 'http://helpy.io/2', AppSettings['settings.parent_site']
    assert_equal 'Helpy 2', AppSettings['settings.parent_company']
    assert_equal 'Support', AppSettings['settings.site_tagline']
    assert_equal 'UA-0000-21', AppSettings['settings.google_analytics_id']
  end

  test 'an admin should be able to modify design' do
    put :update_settings,
      'design.header_logo' => 'logo2.png',
      'design.footer_mini_logo' => 'logo2.png',
      'design.favicon' => 'favicon2.ico',
      'css.search_background' => '000000',
      'css.top_bar' => '000000',
      'css.link_color' => '000000',
      'css.form_background' => '000000',
      'css.still_need_help' => '000000'
    assert_redirected_to :admin_settings
    assert_equal 'logo2.png', AppSettings['design.header_logo']
    assert_equal 'logo2.png', AppSettings['design.footer_mini_logo']
    assert_equal 'favicon2.ico', AppSettings['design.favicon']
    assert_equal '000000', AppSettings['css.search_background']
    assert_equal '000000', AppSettings['css.top_bar']
    assert_equal '000000', AppSettings['css.link_color']
    assert_equal '000000', AppSettings['css.form_background']
    assert_equal '000000', AppSettings['css.still_need_help']
  end

  test 'an admin should be able to toggle locales on and off' do
    # first, toggle off all locales
    AppSettings['i18n.available_locales'] = ''

    put :update_settings,
      'i18n.available_locales' => ['en', 'es', 'de', 'fr', 'et', 'ca', 'ru', 'ja', 'zh-cn', 'zh-tw', 'pt', 'nl']

    assert_redirected_to :admin_settings
    assert_equal ['en', 'es', 'de', 'fr', 'et', 'ca', 'ru', 'ja', 'zh-cn', 'zh-tw', 'pt', 'nl'], AppSettings['i18n.available_locales']
  end

  test 'an admin should be able to toggle display of the widget on and off' do
    # toggle it off
    AppSettings['widget.show_on_support_site'] = 0
    put :update_settings, 'widget.show_on_support_site' => '1'
    assert_equal '1', AppSettings['widget.show_on_support_site']
  end

  test 'an admin should be able to turn email delivery on and off' do
    put :update_settings,
      'email.send_email' => 'false'
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      xhr :post, :create_ticket, topic: { user: { name: 'a user', email: 'anon@test.com' }, name: 'some new private topic', body: 'some body text', forum_id: 1 }, post: { body: 'this is the body' }
    end
  end

end
