$(function(){
  Parse.$ = jQuery;
  _.templateSettings = {
      interpolate : /\{\{(.+?)\}\}/g
  };
  Parse.initialize("tc7RioICzbmNTe875MtAppvFV48EJWjfmgEzJgxf",
                   "uE7UfOO6sGAVAiHAyd0oTq6NqvyKcrJqGv3D3wRy");

  var UsersList = Parse.Collection.extend({
    model: Parse.User,
    comparator: function(user) {
      if (this.forUser) {
        return Math.abs(calculateAge(user.get("birthday")) -
        calculateAge(this.forUser.get("birthday")));
      } else {
        return;
      }
    }
  });

  var spinnerOpts = { lines: 13, length: 28, width: 14, radius: 42, scale: 0.25, corners: 1,
    color: '#000', opacity: 0.25, rotate: 0, direction: 1, speed: 1, trail: 60, fps: 20,
    zIndex: 2e9, className: 'spinner', top: '75px', left: '50%', shadow: false,
    hwaccel: false, position: 'relative' };

  var currentView = "matchingView";

  var UserView = Parse.View.extend({
    tagName: "li",
    template: _.template($('#user-template').html()),
    events: {"click .user-button" : "clicked"},

    clicked: function() {
      var activeView = state.get("activeView");
      if (activeView === "matching") {
        new SelectionView({model: this.model});
      } else if (activeView === "selection") {
        $(".users-list").html("");
        var spinner = new Spinner(spinnerOpts).spin($(".users-list")[0]);
        var testingMode = state.get("testingMode");
        if (testingMode) {
          Parse.Cloud.run('createTestMeetingForUsers', {
            firstUserId: state.get("userToMatch").id,
            secondUserId: this.model.id
          }, {
            success: function(meeting) {
              var firstUser = meeting.get("match").get("firstUser");
              var secondUser = meeting.get("match").get("secondUser");
              spinner.stop();
              alert("Created a meeting with " + firstUser.get("firstName") +
               " " + firstUser.get("lastName") + " and " +
               secondUser.get("firstName") + " " + secondUser.get("lastName"));
              new MatchingView();
            },
            error: console.error
          });
        } else {
          Parse.Cloud.run('saveMatch', {
            firstUserId: state.get("userToMatch").id,
            secondUserId: this.model.id
          }, {
            success: function(match) {
              var firstUser = match.get("firstUser");
              var secondUser = match.get("secondUser");
              spinner.stop();
              alert("Created a match with " + firstUser.get("firstName") +
               " " + firstUser.get("lastName") + " and " +
               secondUser.get("firstName") + " " + secondUser.get("lastName"));
              new MatchingView();
            },
            error: console.error
          });
        }
      }
    },

    render: function() {
      $(this.el).html(this.template(_.extend(this.model.toJSON(), {
        age: calculateAge(this.model.get("birthday"))
      })));
      return this;
    }
  });

  var SelectionView = Parse.View.extend({
    el: ".users-list",
    events: {},

    initialize: function() {
      state.set("userToMatch", this.model);
      state.set("activeView", "selection");
      _.bindAll(this, 'addAll');
      $(".form-title").html("Select a match for " + this.model.get("firstName") + " " + this.model.get("lastName"));
      $(this.el).html("");
      this.users = new UsersList();
      this.users.forUser = this.model;
      this.users.query = new Parse.Query(Parse.User);
      this.users.query.notEqualTo("objectId", this.model.id);
      var testingMode = state.get("testingMode");
      if (!testingMode) {
        this.users.query.equalTo("hasMeetingScheduled", false);
        this.users.query.doesNotExist("activeMatch");
        if (this.model.get("interestedIn") != 2) {
          this.users.query.equalTo("gender", this.model.get("interestedIn"));
        }
        this.users.query.containedIn("interestedIn", [this.model.get("gender"), 2]);
      }
      this.spinner = new Spinner(spinnerOpts).spin($(".users-list")[0]);
      this.users.fetch({
        success: this.addAll
      });
    },

    addOne: function(user) {
      var view = new UserView({ model: user });
      this.$(".users-list").append(view.render().el);
    },

    addAll: function() {
      this.spinner.stop();
      if (this.users.length > 0) {
        this.users.each(this.addOne);
      } else {
        this.$(".users-list").html("<span class='red'>A lonely soul :(</span>");
      }
    }
  });

  var MatchingView = Parse.View.extend({
    el: ".form-stage",
    template: _.template($('#matching-template').html()),
    events: {
      "click .log-out": "logOut",
      "click .testing-mode": "testingMode"
    },

    initialize: function() {
      state.set("activeView", "matching");
      _.bindAll(this, 'addAll' ,'logOut', 'testingMode');
      $(".form-title").html("User matching");
      var testingMode = state.get("testingMode");
      $(this.el).html(this.template());
      this.$(".testing-mode").html(testingMode ? "Normal mode" : "Testing mode");
      this.users = new UsersList();
      this.users.query = new Parse.Query(Parse.User);
      this.users.query.limit(10);
      if (!testingMode) {
        this.users.query.equalTo("hasMeetingScheduled", false);
        this.users.query.doesNotExist("activeMatch");
      }
      this.spinner = new Spinner(spinnerOpts).spin($('.users-list')[0]);
      this.users.fetch({
        success: this.addAll
      });
    },

    addOne: function(user) {
      var view = new UserView({ model: user });
      this.$(".users-list").append(view.render().el);
    },

    addAll: function() {
      this.spinner.stop();
      if (this.users.length > 0) {
        this.users.each(this.addOne);
      } else {
        this.$(".users-list").html("<span class='green'>Everybody has a match :)</span>");
      }
    },

    logOut: function(e) {
      Parse.User.logOut();
      new LogInView();
      this.undelegateEvents();
      delete this;
    },

    testingMode: function(e) {
      var testingMode = state.get("testingMode") || false;
      state.set("testingMode", !testingMode);
      new MatchingView();
      this.undelegateEvents();
      delete this;
    }
  });

  var LogInView = Parse.View.extend({
    el: ".form-stage",
    template: _.template($('#login-template').html()),
    events: {
      "submit form.login-form": "logIn"
    },

    initialize: function() {
      state.set("activeView", "logIn");
      _.bindAll(this, "logIn");
      this.render();
    },

    logIn: function(e) {
      var self = this;
      var username = this.$("#login-username").val();
      var password = this.$("#login-password").val();

      Parse.User.logIn(username, password, {
        success: function(user) {
          if (user.get("isAdministrator")) {
            new MatchingView();
            self.undelegateEvents();
            delete self;
          } else {
            Parse.User.logOut();
            self.$(".login-form .error").html("You have no right to access this page.").show();
            self.$(".login-form button").removeAttr("disabled");
          }
        },
        error: function(user, error) {
          self.$(".login-form .error").html("Invalid username or password. Please try again.").show();
          self.$(".login-form button").removeAttr("disabled");
        }
      });

      this.$(".login-form button").attr("disabled", "disabled");
      return false;
    },

    render: function() {
      $(".form-title").html("Log In");
      $(this.el).html(this.template());
      this.delegateEvents();
    }
  });

  var AppView = Parse.View.extend({
    initialize: function() {
      this.render();
    },

    render: function() {
      if (Parse.User.current()) {
        new MatchingView();
      } else {
        new LogInView();
      }
    }
  });

  var AppState = Parse.Object.extend("AppState");

  var AppRouter = Parse.Router.extend({
   routes: {}
  });

  var state = new AppState();
  new AppRouter();
  new AppView();
  Parse.history.start();

  function calculateAge(birthday) {
    var ageDifMs = Date.now() - birthday.getTime();
    var ageDate = new Date(ageDifMs); // miliseconds from epoch
    return Math.abs(ageDate.getUTCFullYear() - 1970);
  }
});
