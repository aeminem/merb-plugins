require File.dirname(__FILE__) + '/spec_helper'
require 'merb_helpers'

include Merb::ViewContextMixin
include Merb::ErubisCaptureMixin
include Merb::Helpers::Form

describe "error_messages_for" do
  before :each do
    @obj = Object.new
    def @obj.errors() [["foo", "bar"], ["baz", "bat"]] end
  end
  
  it "should build default error messages" do
    errs = error_messages_for(@obj)
    errs.should include("<h2>Form submittal failed because of 2 problems</h2>")
    errs.should include("<li>foo bar</li>")
    errs.should include("<li>baz bat</li>")
  end
  
  it "should accept a custom HTML class" do
    errs = error_messages_for(@obj, nil, "foo")
    errs.should include("<div class='foo'>")
  end
  
  it "should accept a custom header block" do
    errs = error_messages_for(@obj) {|errs| "<h3>Failure: #{errs.size} issues</h3>"}
    errs.should include("<h3>Failure: 2 issues</h3>")
  end
  
  it "should accept a custom error list item block" do
    errs = error_messages_for(@obj, proc {|err| "<li>#{err[0]} column: #{err[1]}</li>"})
    errs.should include("<li>foo column: bar</li>")
  end  
end

describe "form_tag" do
  it_should_behave_like "FakeBufferConsumer"
  
  it "should use the post method by default" do
    form_tag do
      _buffer << "CONTENT"
    end
    _buffer.should match_tag(:form, :method => "post")
    _buffer.should include("CONTENT")
  end
  
  it "should use the get method if set" do
    form_tag :method => :get do
      _buffer << "CONTENT"
    end
    _buffer.should match_tag(:form, :method => "get")
    _buffer.should include("CONTENT")        
  end
  
  it "should fake out the put method if set" do
    form_tag :method => :put do
      _buffer << "CONTENT"
    end
    _buffer.should match_tag(:form, :method => "post")
    _buffer.should match_tag(:input, :type => "hidden", :name => "_method", :value => "put")    
  end
  
  it "should fake out the delete method if set" do
    form_tag :method => :delete do
      _buffer << "CONTENT"
    end
    _buffer.should match_tag(:form, :method => "post")
    _buffer.should match_tag(:input, :type => "hidden", :name => "_method", :value => "delete")
  end
  
  it "should silently set method to post if an unsupported method is used" do
      form_tag :method => :dodgy do
        _buffer << "CONTENT"
      end
      _buffer.should match_tag(:form, :method => "post")
      _buffer.should_not match_tag(:input, :type => "hidden", :name => "_method", :value => "dodgy")
  end
  
  it "should take create a form" do
    form_tag(:action => "foo", :method => :post) do
      _buffer << "Hello"
    end
    _buffer.should match_tag(:form, :action => "foo", :method => "post")
    _buffer.should include("Hello")
  end
  
  it "should set a form to be mutlipart" do
    form_tag( :action => "foo", :method => :post, :multipart => true ) do
      _buffer << "CONTENT"
    end
    _buffer.should match_tag( :form, :action => "foo", :method => "post", :enctype => "multipart/form-data")
    _buffer.should include("CONTENT")  
  end
end

describe "form_for" do
  it_should_behave_like "FakeBufferConsumer"  
  
  it "should wrap the contents in a form tag" do
    form_for(:obj) do
      _buffer << "Hello"
    end
    _buffer.should match_tag(:form, :method => "post")
    _buffer.should match_tag(:input, :type => "hidden", :value => "put", :name => "_method")    
  end
  
  it "should set the method to post be default" do
    @obj2 = FakeModel2.new
    form_for(:obj2) do
    end
    _buffer.should match_tag(:form, :method => "post")
    _buffer.should_not match_tag(:input, :type => "hidden", :name => "_method")
  end
  
  it "should set the method to post if the object does not respond to new_record?" do
    @obj3 = FakeModel3.new
    form_for(:obj3) do
    end
    _buffer.should match_tag(:form, :method => "post")
    _buffer.should_not match_tag(:input, :type => "hidden", :name => "_method")
  end
  
  it "should support PUT if the object passed in is not a new_record? via a hidden field" do
    form_for(:obj) do
    end
    _buffer.should match_tag(:form, :method => "post")
    _buffer.should match_tag(:input, :type => "hidden", :value => "put", :name => "_method")    
  end
  
  it "should set a form to be mutlipart" do
    form_for(:obj, :multipart => true) do
    end
    _buffer.should match_tag( :form, :method => "post", :enctype => "multipart/form-data")
  end
  
end

describe "fields_for" do
  it_should_behave_like "FakeBufferConsumer"
  
  it "should dump the contents in the context of the object" do
    fields_for(:obj) do
      text_control(:foo).should match_tag(:input, :type => "text", :value => "foowee")
      _buffer << "Hello"
    end
    _buffer.should == "Hello"
  end  

  it "should be able to modify the context midstream" do
    @obj2 = FakeModel2.new    
    form_for(:obj) do
      text_control(:foo).should match_tag(:input, :type => "text", :value => "foowee")      
      fields_for(:obj2) do
        text_control(:foo).should match_tag(:input, :name => "fake_model2[foo]", :type => "text", :value => "foowee2")
      end
      text_control(:foo).should match_tag(:input, :type => "text", :value => "foowee")      
    end
  end
  
  it "should handle an explicit nil attribute" do
    fields_for(:obj, nil) do
      _buffer << text_control(:foo)
    end
    _buffer.should match_tag(:input, :name => "fake_model[foo]", :value => "foowee", :type => "text")
  end
  
end

describe "text_field (basic)" do
  it_should_behave_like "FakeBufferConsumer"
  
  it "should return a basic text field based on the values passed in" do
    text_field(:name => "foo", :value => "bar").should match_tag( :input, :type => "text", :name => "foo", :value => "bar")
  end
  
  it "should provide an additional label tag if the :label option is passed in" do
    result = text_field(:label => "LABEL" )
    result.should match(/<label>LABEL<\/label><input type="text"\s*\/>/)
  end 
end

describe "text_control (data bound)" do
  it_should_behave_like "FakeBufferConsumer"
  
  it "should take a string object and return a useful text control" do
    f = form_for :obj do
      text_control(:foo).should match_tag(:input, :type => "text", :name => "fake_model[foo]", :value => "foowee")
    end
  end

  it "should take additional attributes and use them" do
    form_for :obj do
      text_control(:foo, :bar => "7").should match_tag(:input, :type => "text", :name => "fake_model[foo]", :value => "foowee", :bar => "7")
    end
  end
  
  it "should provide an additional label tag if the :label option is passed in" do
    form_for :obj do
      _buffer << text_control(:foo, :label => "LABEL")
    end
    _buffer.should match(/<label.*>LABEL<\/label><input/)
    res = _buffer.scan(/<[^>]*>/)
    res[2].should_not match_tag(:input, :label => "LABEL")
  end
  
  it "should not errorify the field for a new object" do
    f = form_for :obj do
      text_control(:foo, :bar =>"7").should_not match_tag(:input, :type => "text", :name => "fake_model[foo]", :class => "error")    
    end
  end
  
  it "should errorify a field for a model with errors" do
    model = mock("model")
    model.stub!(:new_record?).and_return(true)
    model.stub!(:class).and_return("MyClass")
    model.stub!(:foo).and_return("FOO")
    errors = mock("errors")
    errors.should_receive(:on).with(:foo).and_return(true)
    
    model.stub!(:errors).and_return(errors)
    
    f = form_for model do
      text_control(:foo).should match_tag(:input, :class => "error")
    end
  end
end

describe "password_field (basic)" do
  it_should_behave_like "FakeBufferConsumer"
  
  it "should return a basic password field, but omit the value" do
    password_field(:name => "foo", :value => "bar").should match_tag(:input, :type => "password", :name => "foo")
  end
  
  it "should provide an additional label tag if the :label option is passed in" do
    result = password_field(:label => "LABEL" )
    result.should match(/<label.*>LABEL<\/label><input type="password"\s*\/>/)
  end
end

describe "password_control (data bound)" do
  it_should_behave_like "FakeBufferConsumer"
  
  it "should take a string object and return a useful password control, but omit the value" do
    f = form_for :obj do
      password_control(:foo).should match_tag(:input, :type => "password", :name => "fake_model[foo]")
    end
  end

  it "should take additional attributes and use them" do
    form_for :obj do
      password_control(:foo, :bar => "7").should match_tag(:input, :type => "password", :name => "fake_model[foo]", :bar => "7")
    end
  end
  
  it "should provide an additional label tag if the :label option is passed in" do
    form_for :obj do
      _buffer << password_control(:foo, :label => "LABEL")
    end
    _buffer.should match(/<label.*>LABEL<\/label><input/)
    res = _buffer.scan(/<[^>]*>/)
    res[2].should_not match_tag(:input, :label => "LABEL")
  end
  
  it "should not errorify the field for a new object" do
    f = form_for :obj do
      password_control(:foo, :bar =>"7").should_not match_tag(:input, :class => "error")    
    end
  end
  
  it "should errorify a field for a model with errors" do
    model = mock("model")
    model.stub!(:new_record?).and_return(true)
    model.stub!(:class).and_return("MyClass")
    model.stub!(:foo).and_return("FOO")
    errors = mock("errors")
    errors.should_receive(:on).with(:foo).and_return(true)
    
    model.stub!(:errors).and_return(errors)
    
    f = form_for model do
      password_control(:foo).should match_tag(:input, :class => "error")
    end
  end
  
end

describe "checkbox_field (basic)" do
  it "should return a basic checkbox based on the values passed in" do
    checkbox_field(:name => "foo", :checked => "checked").should match_tag(:input, :class => "checkbox", :name => "foo", :checked => "checked")
  end

  it "should return a basic checkbox with :boolean => true" do
    checkbox_field(:name => "foo", :checked => "checked", :boolean => true).should match_tag(:input, :class => "checkbox", :name => "foo", :checked => "checked")
  end

  it "should return a basic checkbox with a value other than 1/0" do
    checkbox_field(:name => "choices[]", :boolean => false, :value => "dog").should match_tag(:input, :class => "checkbox", :name => "choices[]", :value => "dog")
  end
  
  it "should provide an additional label tag if the :label option is passed in" do
    result = checkbox_field(:label => "LABEL" )
    result.should match(/<label>LABEL<\/label><input/)
    res = result.scan(/<[^>]*>/)
    res[2].should_not match_tag(:input, :label => "LABEL")
  end
end

describe "checkbox_control (data bound)" do
  it_should_behave_like "FakeBufferConsumer"  
    
  it "should take a string and return a useful checkbox control" do
    form_for :obj do
      checkbox_control(:baz).should match_tag(:input, :type =>"checkbox", :name => "fake_model[baz]", :class => "checkbox", :value => "1", :checked => "checked", :id => "fake_model_baz")
      checkbox_control(:bat).should match_tag(:input, :type =>"checkbox", :name => "fake_model[bat]", :class => "checkbox", :value => "0")
    end
  end
  
  it "should allow a user to set the :off value" do
    form_for :obj do
      checkbox_control(:baz, :off => "off", :on => "on").should match_tag(:input, :type =>"checkbox", :name => "fake_model[baz]", :class => "checkbox", :value => "on", :checked => "checked")
      checkbox_control(:bat, :off => "off", :on => "on").should match_tag(:input, :type =>"checkbox", :name => "fake_model[bat]", :class => "checkbox", :value => "off")
    end
  end
  
  it "should evaulate nil, false, 0 and '0' to false. All else to true" do
    send(:col_val_to_bool, nil).should   == false
    send(:col_val_to_bool, false).should == false
    send(:col_val_to_bool, 0).should     == false
    send(:col_val_to_bool, '0').should   == false
    send(:col_val_to_bool, 1).should     == true
    send(:col_val_to_bool, '1').should   == true
    send(:col_val_to_bool, true).should  == true
  end

  it "should render controls with errors if their attribute contains an error" do
    form_for :obj do
      checkbox_control(:bazbad).should match_tag(:input, :type =>"checkbox", :name => "fake_model[bazbad]", 
        :class => "error checkbox", :value => "1", :checked => "checked")
      checkbox_control(:batbad).should match_tag(:input, :type =>"checkbox", :name => "fake_model[batbad]", 
        :class => "error checkbox", :value => "0")        
    end
  end  
  
  it "should provide an additional label tag if the :label option is passed in" do
    form_for :obj do
      _buffer << checkbox_control(:foo, :label => "LABEL")
    end
    _buffer.should match( /<label.*>LABEL<\/label><input/ )
    res = _buffer.scan(/<[^>]*>/)
    res[2].should_not match_tag(:input, :label => "LABEL")
    end
    
    it "should not errorify the field for a new object" do
      f = form_for :obj do
        checkbox_control(:foo, :bar =>"7").should_not match_tag(:input, :type => "checkbox", :class => "error checkbox")
      end
    end

    it "should errorify a field for a model with errors" do
      model = mock("model")
      model.stub!(:new_record?).and_return(true)
      model.stub!(:class).and_return("MyClass")
      model.stub!(:foo).and_return("FOO")
      errors = mock("errors")
      errors.should_receive(:on).with(:foo).and_return(true)
    
      model.stub!(:errors).and_return(errors)
    
      f = form_for model do
        checkbox_control(:foo, :bar =>"7").should match_tag(:input, :type => "checkbox", :class => "error checkbox")
      end
    end
end

describe "hidden_field (basic)" do
  
  it "should return a basic checkbox based on the values passed in" do
    hidden_field(:name => "foo", :value => "bar").should match_tag(:input, :type => "hidden", :name => "foo", :value => "bar")
  end
  
  it "should not render a label if the :label option is passed in" do
    res = hidden_field(:label => "LABEL")
    res.should_not match(/<label>LABEL/)
    res.should_not match_tag(:input, :label=> "LABEL")  
  end
end

describe "hidden_control (data bound)" do
  it_should_behave_like "FakeBufferConsumer"
    
  it "should take a string and return a useful checkbox control" do
    form_for :obj do 
      hidden_control(:foo).should match_tag(:input, :type =>"hidden", :name => "fake_model[foo]", :value => "foowee")
    end
  end
  
  it "should render controls with errors if their attribute contains an error" do
    form_for :obj do
      hidden_control(:foobad).should match_tag(:input, :type =>"hidden", :name => "fake_model[foobad]", :value => "foowee", :class => "error")
    end
  end
  
  it "should not render a label if the :label option is passed in" do
    form_for :obj do
      res = hidden_control(:foo, :label => "LABEL")
      res.should_not match(/<label>LABEL/)
      res.should_not match_tag(:input, :label=> "LABEL")  
    end
  end
  
  it "should not errorify the field for a new object" do
    f = form_for :obj do
      hidden_control(:foo, :bar =>"7").should_not match_tag(:input, :type => "hidden", :class => "error")
    end
  end

  it "should not errorify a field for a model with errors" do
    model = mock("model")
    model.stub!(:new_record?).and_return(true)
    model.stub!(:class).and_return("MyClass")
    model.stub!(:foo).and_return("FOO")
    errors = mock("errors")
    errors.should_receive(:on).with(:foo).and_return(true)
  
    model.stub!(:errors).and_return(errors)
  
    f = form_for model do
      hidden_control(:foo, :bar =>"7").should match_tag(:input, :type => "hidden", :name => "my_class[foo]", :class => "error")
    end
  end
    
end

describe "radio button (basic)" do
  it "should should return a basic radio button based on the values passed in" do
    radio_field(:name => "foo", :value => "bar").should match_tag(:input, :type => "radio", :name => "foo", :value => "bar")
  end
  
  it "should provide an additional label tag if the :label option is passed in" do
    result = radio_field(:name => "foo", :value => "bar", :label => "LABEL")
    result.should match(/<label.*>LABEL<\/label><input/)
    res = result.scan(/<[^>]*>/)
    res[2].should_not match_tag(:input, :label => "LABEL")
  end
  
end

describe "radio button groups (data bound)" do
  it_should_behave_like "FakeBufferConsumer"
  
  it "should return a group of radio buttons" do
    form_for :obj do
      radio = radio_group_control(:foo, [:foowee, :baree]).scan(/<[^>]*>/)
      radio[2].should match_tag(:input, :type => "radio", :name => "fake_model[foo]", :value => "foowee", :selected => "selected")
      radio[5].should match_tag(:input, :type => "radio", :name => "fake_model[foo]", :value => "baree")
      radio[3].should not_match_tag(:selected => "selected")
    end
  end
  
  it "should provide an additional label tag if the :label option is passed in" do
    form_for :obj do
      radio = radio_group_control(:foo, [:foowee, :baree])
      radio.scan( /<label.*?>(foowee|baree)<\/label><input/ ).size.should == 2
      radio = radio.scan(/<[^>]*>/)
      radio[1].should_not match_tag(:input, :label => "LABEL")
      radio[4].should_not match_tag(:input, :label => "LABEL")
    end
  end
end

describe "text area (basic)" do
  it "should should return a basic text area based on the values passed in" do
    text_area_field("foo", :name => "foo").should match_tag(:textarea, :name => "foo")
  end
  
  it "should handle a nil content" do
    text_area_field(nil, :name => "foo").should == "<textarea name=\"foo\"></textarea>"
  end
  
  it "should handle a nil attributes hash" do
    text_area_field("CONTENT", nil).should == "<textarea>CONTENT</textarea>"
  end
  
  it "should render a label when the label is passed in" do
    result = text_area_field( "CONTENT", :name => "foo", :value => "bar", :label => "LABEL")
    result.should match(/<label.*>LABEL<\/label><textarea/)
    res = result.scan(/<[^>]*>/)
    res[1].should_not match_tag(:textarea, :label => "LABEL")
  end
end

describe "select (data bound)" do
  
  it_should_behave_like "FakeBufferConsumer"

  it "should render the select tag with the correct id and name" do
    form_for :obj do
      content = select_control( :foo )
      content.should match_tag( :select, :id => "fake_model_foo", :name => "fake_model[foo]" )
    end
  end
  
  it "should include a blank option" do
    form_for :obj do
      content = select_control( :foo, :include_blank => true )
      content.should match_tag( :option, :value => '')
    end
  end
  
  it "should render a prompt option without a value" do
    form_for :obj do
      content = select_control( :foo, :prompt => "Choose" )
    end
  end
  
  it "should render a select tag with options" do
    form_for :obj do
      content = select_control( :foo, :class => 'class1 class2', :title => 'This is the title' )
      content.should match_tag( :select, :class => "class1 class2", :title=> "This is the title" ) 
    end
  end
  
  it "should render a select tag with options and a blank option" do
    form_for :obj do
      content = select_control( :foo, :title => "TITLE", :include_blank => true )
      content.should match_tag( :select, :title => "TITLE" ) 
      content.should match_tag( :option, :value => '' )
    end
  end
  
  it "should render the text as the value if no text_method is specified" do
    form_for :obj do
      content = select_control( :foo, :collection => [FakeModel] )
      content.should match_tag( :option, :value => "FakeModel" )
    end
  end
      
end

describe "option tag generation (data bound)" do
  it_should_behave_like "FakeBufferConsumer"
  
  it "should use text_method and value_method for tag generation" do
    content = options_from_collection_for_select( [FakeModel.new, FakeModel2.new], :text_method => 'foo', :value_method => 'bar' )
    content.should match_tag( :option, :content => "foowee", :value => "7" )
    content.should match_tag( :option, :content => "foowee2", :value => "barbar" )
  end
  
  it "should render a hash of arrays as a grouped select box" do
    @model1 = FakeModel.new ; @model1.make = "Ford"   ; @model1.model = "Mustang"   ; @model1.vin = '1' 
    @model2 = FakeModel.new ; @model2.make = "Ford"   ; @model2.model = "Falcon"    ; @model2.vin = '2'
    @model3 = FakeModel.new ; @model3.make = "Holden" ; @model3.model = "Commodore" ; @model3.vin = '3'
  
    collection = [@model1, @model2, @model3].group_by( &:make )
    content = options_from_collection_for_select(collection, :text_method => 'model', :value_method => 'vin', :selected => '1')
    
    content.should match_tag( :optgroup, :label => "Ford" )
    content.should match_tag( :option, :selected => "selected", :value => "1", :content => "Mustang" )
    content.should match_tag( :option, :value => "2", :content => "Falcon" )
    content.should match_tag( :optgroup, :label => "Holden" )
    content.should match_tag( :option, :value => "3", :content => "Commodore" )
  end
    
  it "should humanize and titlize keys in the label for the option group" do
    collection = { :some_snake_case_key => [FakeModel] }
    form_for :obj do
      content = select_control( :foo, :collection => collection )
      content.should match_tag( :optgroup, :label => "Some Snake Case Key" )
    end
  end

  
end

describe "option tags generation (basic)" do
  it_should_behave_like "FakeBufferConsumer"
  
  before do
    @collection = [['rabbit','Rabbit'],['horse','Horse'],['bird','Bird']]
  end
  
  it "should provide an option tag for each item in the collection" do
    result = options_for_select( @collection )
    doc = Hpricot( result )
    (doc/"option").size.should == 3
  end
  
  it "should provide a blank option" do
    content = options_for_select(@collection, :include_blank => true )
    content.should match_tag( :option, :value => '' )
  end
  
  it "should provide a prompt option" do
    content = options_for_select( [], :prompt => 'Choose' )
    content.should match_tag( :option, :value => '', :content => 'Choose' )
  end
  
  it "should provide selected options by value" do
    content = options_for_select( [['rabbit','Rabbit'],['chicken','Chicken']], :selected => 'rabbit' )
    content.should match_tag( :option, :value => 'rabbit', :selected => 'selected', :content => 'Rabbit' )
    content.should_not match_tag( :option, :value => 'chicken', :selected => nil, :content => 'Chicken' )
  end
  
  it "should render a hash of options as optgroup" do
    collection = { :fruit => [['orange','Orange'],['banana','Banana']], :vegatables => [['corn','Corn']]}
    content = options_for_select(collection, :selected => 'banana')
    content.should match_tag( :optgroup, :label => 'Fruit' )
    content.should match_tag( :optgroup, :label => 'Vegatables' )
    content.should match_tag( :option, :value => 'banana', :selected => 'selected', :content => 'Banana' )
  end
  
end

describe "fieldset generation (basic)" do
  it_should_behave_like "FakeBufferConsumer"

  it "should provide legend option" do
    fieldset :legend => 'TEST' do
      _buffer << "CONTENT"
    end
    _buffer.should include("CONTENT")
    _buffer.should match_tag(:fieldset, {})
    _buffer.should match_tag(:legend, :content => 'TEST')
  end
end

describe "file_field (basic)" do
  it_should_behave_like "FakeBufferConsumer"
  
  it "should return a basic file field based on the values passed in" do
    file_field(:name => "foo", :value => "bar").should match_tag( :input, :type => "file", :name => "foo", :value => "bar")
  end
  
  it "should wrap the field in a label if the :label option is passed to the file_field" do
    result = file_field(:label => "LABEL" )
    result.should match(/<label>LABEL<\/label><input type="file"\s*\/>/)
  end
end

describe "file_control (data bound)" do
  it_should_behave_like "FakeBufferConsumer"
  
  it "should take a string object and return a useful file control" do
    f = form_for :obj do
      file_control(:foo).should match_tag(:input, :type => "file", :name => "fake_model[foo]", :value => "foowee")
    end
  end

  it "should take additional attributes and use them" do
    form_for :obj do
      file_control(:foo, :bar => "7").should match_tag(:input, :type => "file", :name => "fake_model[foo]", :value => "foowee", :bar => "7")
    end
  end
  
  it "should wrap the file_control in a label if the :label option is passed in" do
    form_for :obj do
      _buffer << text_control(:foo, :label => "LABEL")
    end
    _buffer.should match(/<label.*>LABEL<\/label><input/)
    res = _buffer.scan(/<[^>]*>/)
    res[2].should_not match_tag(:input, :label => "LABEL")
  end
end

describe "submit_field (basic)" do
  it "should return a basic submit input based on the values passed in" do
    submit_field(:name => "foo", :value => "bar").should match_tag(:input, :type => "submit", :name => "foo", :value => "bar")
  end
  
  it "should provide an additional label tag if the :label option is passed in" do
    result = submit_field(:value => "foo", :label => "LABEL")
    result.should match(/<input.*type="submit"/)
    result.should match(/<input.*name="submit"/)
    result.should match(/<input.*value="foo"/)
    result.should match(/<input.*label="LABEL"/)
  end
end


describe "delete_button" do
  before(:each) do
    @obj = mock("a model")
    @obj.stub!(:id).and_return(5)
    Merb::Router.prepare do |r|
      r.resources :objs
    end
  end

  it "should return a button inside of a form for the object" do
    result = delete_button(:obj, @obj)
    result.should match_tag(:form, :action => "/objs/#{@obj.id}", :method => "post")
    result.should match_tag(:input, :type => "hidden", :value => "delete", :name => "_method")
    result.should match_tag(:button, :type => "submit")
    result.should match(/<button.*>Delete<\/button>/)
  end

  it "should allow you to modify it's contents" do
    result = delete_button(:obj, @obj, "Remove")
    result.should match(/<button.*>Remove<\/button>/)
  end
end