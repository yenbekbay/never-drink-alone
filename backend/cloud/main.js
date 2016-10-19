/* jshint -W082 */

/*
PUBLIC
*/
require('cloud/app.js');

/*
JOBS
*/

Parse.Cloud.job("generateInterests", function(request, status) {
  var industryCodes = [];
  for (var key in ruIndustries) {
    if (ruIndustries.hasOwnProperty(key)) {
      industryCodes.push(key);
    }
  }
  var interestIndex = 0;
  generateNextInterest();
  function generateNextInterest() {
    if (interestIndex >= interests.length) {
      status.success("Generated interests successfully");
    } else {
      generateInterestForIndustryCode(industryCodes[interestIndex], {
        success: function(interest) {
          interestIndex++;
          generateNextInterest();
        },
        error: function(error) {
          console.error(error);
          interestIndex++;
          generateNextInterest();
        }
      });
    }
  }
});

Parse.Cloud.job("generateMeetings", function(request, status) {
  Parse.Cloud.useMasterKey();
  var query = new Parse.Query(Parse.User);
  query.find({
    success: function(users) {
      var userIndex = 0;
      generateNextMeeting();
      function generateNextMeeting() {
        if (userIndex >= users.length) {
          status.success("Generated meetings for users successfully");
        } else {
          generateMeetingForUser(users[userIndex], {
            success: function(meeting) {
              if (meeting) {
                console.log("Generated a meeting for user " +
                  meeting.get("match").get("firstUser").id);
                console.log("Generated a meeting for user " +
                  meeting.get("match").get("secondUser").id);
              }
              userIndex++;
              generateNextMeeting();
            },
            error: function(error) {
              console.error(error);
              userIndex++;
              generateNextMeeting();
            }
          });
        }
      }
    },
    error: status.error
  });
});

Parse.Cloud.job("cleanUp", function(request, status) {
  Parse.Cloud.useMasterKey();
  var meetingQuery = new Parse.Query("Meeting");
  meetingQuery.equalTo("confirmed", false);
  meetingQuery.equalTo("cancelled", false);
  meetingQuery.find({
    success: function(meetings) {
      var meetingIndex = 0;
      cancelNextMeeting();
      function cancelNextMeeting() {
        if (meetingIndex === meetings.length) {
          status.success("Cleaned up successfully");
        } else {
          cancelMeeting(meetings[meetingIndex], {
            success: function() {
              meetingIndex++;
              cancelNextMeeting();
            },
            error: function(error) {
              console.error(error);
              meetingIndex++;
              cancelNextMeeting();
            }
          });
        }
      }
    },
    error: status.error
  });
});

Parse.Cloud.job("checkMeetings", function(request, status) {
  Parse.Cloud.useMasterKey();
  var meetingQuery = new Parse.Query("Meeting");
  meetingQuery.equalTo("confirmed", true);
  meetingQuery.equalTo("completed", false);
  meetingQuery.find({
    success: function(meetings) {
      var meetingIndex = 0;
      checkNextMeeting();
      function checkNextMeeting() {
        if (meetingIndex >= meetings.length) {
          status.success("Checked meetings successfully");
        } else {
          checkMeeting(meetings[meetingIndex], {
            success: function() {
              meetingIndex++;
              checkNextMeeting();
            },
            error: function(error) {
              console.error(error);
              meetingIndex++;
              checkNextMeeting();
            }
          });
        }
      }
    },
    error: status.error
  });
});

/*
DEFINITIONS
*/

Parse.Cloud.define("getCodeForIndustry", function(request, response) {
  if (!request.params.industry) {
    response.error("Please specify industry");
    return;
  }
  for (var industryCode in enIndustries) {
    if (enIndustries.hasOwnProperty(industryCode)) {
      if (enIndustries[industryCode] === request.params.industry) {
        response.success(industryCode);
        return;
      }
    }
  }
});

Parse.Cloud.define("createTestMeetingForUsers", function(request, response) {
  if (!request.params.firstUserId || !request.params.secondUserId) {
    response.error("Please specify firstUserId and secondUserId");
    return;
  }
  Parse.Cloud.useMasterKey();
  resetFirstUser();
  function resetFirstUser() {
    cancelMeetingForUserId(request.params.firstUserId, {
      success: resetSecondUser,
      error: function(error) {
        console.error(error);
        resetSecondUser();
      }
    });
  }
  function resetSecondUser() {
    cancelMeetingForUserId(request.params.secondUserId, {
      success: generateMeeting,
      error: function(error) {
        console.error(error);
        generateMeeting();
      }
    });
  }
  function generateMeeting() {
    getMatchForUserIds(request.params.firstUserId,
      request.params.secondUserId, {
      success: function(match) {
        generateMeetingForMatch(match, {
          success: function(meeting) {
            response.success(meeting);
          },
          error: response.error
        });
      },
      error: response.error
    });
  }
});

Parse.Cloud.define("karmaTransaction", function(request, response) {
  Parse.Cloud.useMasterKey();
  var KarmaTransaction = Parse.Object.extend("KarmaTransaction");
  var karmaTransaction = new KarmaTransaction();
  userQuery = new Parse.Query(Parse.User);
  userQuery.get(request.params.userId, {
    success: function(user) {
      user.set("karma", user.get("karma") + request.params.amount);
      user.save();
      karmaTransaction.save({
        user: user,
        amount: request.params.amount,
        description: request.params.description
      }, {
        success: response.success,
        error: function(karmaTransaction, error) {
          response.error(error);
        }
      });
    },
    error: response.error
  });
});

Parse.Cloud.define("userMissedMeeting", function(request, response) {
  Parse.Cloud.useMasterKey();
  var userQuery = new Parse.Query(Parse.User);
  userQuery.get(request.params.userId, {
    success: function(user) {
      sendPushNotification(user, "Вы не пришли на встречу, -4 от кармы.",
        false, {
        success: function() {
          response.success("Sent a push notification");
        },
        error: function(error) {
          response.error(error);
        }
      });
    },
    error: response.error
  });
});

Parse.Cloud.define("notifyMeetingUser", function(request, response) {
  Parse.Cloud.useMasterKey();
  var userMeetingQuery = new Parse.Query("UserMeeting");
  userMeetingQuery.get(request.params.userMeetingId, {
    success: function(userMeeting) {
      userQuery = new Parse.Query(Parse.User);
      userQuery.get(request.params.receivingUserId, {
        success: function(receivingUser) {
          var hasAccepted = userMeeting.get("hasAccepted");
          var hasRejected = userMeeting.get("hasRejected");
          var message;
          var reload;
          if (hasAccepted) {
            message = request.params.sendingUserName + " подтвердил, что " +
              "придет на встречу";
            reload = false;
          } else if (hasRejected) {
            message = "К сожалению, встреча c " +
              request.params.sendingUserName + " сорвалась. Следующая " +
              "возможность - в полдень завтра.";
            reload = true;
          } else {
            response.error("Nothing to notify about");
            return;
          }
          sendPushNotification(receivingUser, message, reload, {
            success: function() {
              response.success("Sent a push notification");
            },
            error: function(error) {
              response.error(error);
            }
          });
        },
        error: response.error
      });
    },
    error: response.error
  });
});

Parse.Cloud.define("saveMatch", function(request, response) {
  Parse.Cloud.useMasterKey();
  var Match = Parse.Object.extend("Match");
  var match = new Match();
  saveMatchWithUserIds(match, request.params.firstUserId,
    request.params.secondUserId, response);
});

Parse.Cloud.define("updateMeetingStatus", function(request, response) {
  var userMeetingQuery = new Parse.Query("UserMeeting");
  userMeetingQuery.get(request.params.firstUserMeetingId, {
    success: function(firstUserMeeting) {
      userMeetingQuery.get(request.params.secondUserMeetingId, {
        success: function(secondUserMeeting) {
          if (firstUserMeeting.get("meeting").id == secondUserMeeting
            .get("meeting").id) {
              var meeting = firstUserMeeting.get("meeting");
              if (firstUserMeeting.get("hasAccepted") &&
                secondUserMeeting.get("hasAccepted")) {
                meeting.save({ confirmed: true }, {
                  success: response.success,
                  error: function(meeting, error) {
                    response.error(error);
                  }
                });
              } else if (firstUserMeeting.get("hasRejected") &&
                secondUserMeeting.get("hasRejected")) {
                meeting.save({ cancelled: true }, {
                  success: response.success,
                  error: function(meeting, error) {
                    response.error(error);
                  }
                });
              } else {
                console.log("No status yet for meeting " + meeting.id);
                response.success(null);
              }
          } else {
            response.error("User meetings must refer to the same meeting");
          }
        },
        error: response.error
      });
    },
    error: response.error
  });
});

/*
FUNCTIONS
*/

function generateInterestForIndustryCode(industryCode, response) {
  var interestQuery = new Parse.Query("Interest");
  interestQuery.equalTo("code", industryCode);
  interestQuery.first({
    success: function(interest) {
      if (interest) {
        response.success(interest);
      } else {
        createMeeting();
      }
    },
    error: function(error) {
      createMeeting();
    }
  });
  function createMeeting() {
    var Interest = Parse.Object.extend("Interest");
    var interest = new Interest();
    interest.save({
      name: ruIndustries[industryCode],
      code: industryCode
    }, {
      success: response.success,
      error: function(interest, error) {
        response.error(error);
      }
    });
  }
}

function generateMeetingForUser(user, response) {
  if (user.get("hasMeetingScheduled")) {
    response.error("User " + user.id + " already has a meeting scheduled");
  } else {
    findMatchForUser(user, {
      success: function(match) {
        if (match) {
          match.save({
            active: false
          }, {
            success: function(match) {
              generateMeetingForMatch(match, response);
            },
            error: function(match, error) {
              response.error(error);
            }
          });
        } else {
          response.error("No match found for user " + user.id);
        }
      },
      error: response.error
    });
  }
}

function generateMeetingForMatch(match, response) {
  var Meeting = Parse.Object.extend("Meeting");
  var meeting = new Meeting();
  meeting.set("match", match);
  if (!match.get("interests")) {
    saveCommonInterestsForMatch(match);
  }
  var meetingQuery = new Parse.Query("Meeting");
  meetingQuery.equalTo("match", match);
  meetingQuery.first({
    success: function(existingMeeting) {
      if (existingMeeting) {
        response.success(null);
      } else {
        findMeetingPlaceForMatch(match, {
          success: handleMeetingPlace,
          error: function(error) {
            handleMeetingPlace(null);
          }
        });
      }
    },
    error: response.error
  });
  function handleMeetingPlace(meetingPlace) {
    meeting.set("meetingPlace", meetingPlace);
    findTimeSlotForMatch(meeting.get("match"), {
      success: handleTimeSlot,
      error: function(error) {
        handleTimeSlot(null);
      }
    });
  }
  function handleTimeSlot(timeSlot) {
    meeting.set("timeSlot", timeSlot);
    meeting.set("date", getDateFromTimeSlot(timeSlot));
    createUserMeetingsForMatch(meeting.get("match"), meeting, {
      success: handleUserMeetings,
      error: response.error
    });
  }
  function handleUserMeetings(userMeetings) {
    meeting.save({
      confirmed: false,
      cancelled: false,
      completed: false
    }, {
      success: function(meeting) {
        var firstUser = meeting.get("match").get("firstUser");
        var secondUser = meeting.get("match").get("secondUser");
        sendInvitationPushNotification(firstUser, {
          success: function() {
            sendInvitationPushNotification(secondUser, {
              success: function() {
                console.log("Sent a push notification to user " +
                  firstUser.id);
                console.log("Sent a push notification to user " +
                  secondUser.id);
                response.success(meeting);
              },
              error: response.error
            });
          },
          error: response.error
        });
      },
      error: function(userMeeting, error) {
        response.error(error);
      }
    });
  }
}

function cancelMeetingForUserId(userId, response) {
  var userQuery = new Parse.Query(Parse.User);
  userQuery.get(userId, {
    success: function(user) {
      findMatchForUser(user, {
        success: function(match) {
          var meetingQuery = new Parse.Query("Meeting");
          meetingQuery.equalTo("match", match);
          meetingQuery.first({
            success: function(meeting) {
              if (meeting) {
                cancelMeeting(meeting, response);
              } else {
                response.success();
              }
            },
            error: response.error
          });
        },
        error: response.error
      });
    },
    error: response.error
  });
}

function cancelMeeting(meeting, response) {
  meeting.set("cancelled", true);
  meeting.set("completed", true);
  meeting.save();
  var matchQuery = new Parse.Query("Match");
  matchQuery.get(meeting.get("match").id, {
    success: handleMatch,
    error: response.error
  });
  function handleMatch(match) {
    var userQuery = new Parse.Query(Parse.User);
    userQuery.get(match.get("firstUser").id, {
      success: function(firstUser) {
        firstUser.unset("activeMatch");
        firstUser.save({
          hasMeetingScheduled: false,
          hasUndecidedMeeting: false
        }, {
          success: function(firstUser) {
            console.log("Cancelled meeting for user " + firstUser.id);
            handleFirstUser(firstUser, match);
          },
          error: function(firstUser, error) {
            response.error(error);
          }
        });
      },
      error: response.error
    });
  }
  function handleFirstUser(firstUser, match) {
    var userQuery = new Parse.Query(Parse.User);
    userQuery.get(match.get("secondUser").id, {
      success: function(secondUser) {
        secondUser.unset("activeMatch");
        secondUser.save({
          hasMeetingScheduled: false,
          hasUndecidedMeeting: false
        }, {
          success: function(secondUser) {
            console.log("Cancelled meeting for user " + secondUser.id);
            handleUsers(firstUser, secondUser);
          },
          error: function(secondUser, error) {
            response.error(error);
          }
        });
      },
      error: response.error
    });
  }
  function handleUsers(firstUser, secondUser) {
    cancelMeetingForUser(firstUser, secondUser, meeting, {
      success: function() {
        cancelMeetingForUser(secondUser, firstUser, meeting, response);
      },
      error: response.error
    });
  }
}

function cancelMeetingForUser(receivingUser, otherUser, meeting, response) {
  var userMeetingQuery = new Parse.Query("UserMeeting");
  userMeetingQuery.equalTo("user", receivingUser);
  userMeetingQuery.equalTo("meeting", meeting);
  userMeetingQuery.first({
    success: function(userMeeting) {
      var hasAccepted = userMeeting.get("hasAccepted");
      var hasSeen = userMeeting.get("hasSeen");
      var message;
      var reload;
      if (hasAccepted || !hasSeen) {
        message = "К сожалению, встреча c " + otherUser.get("firstName") +
          " сорвалась. Следующая возможность - в полдень завтра.";
      } else {
        message = "Ваша встреча с " + otherUser.get("firstName") +
          " отменилась, -2 от кармы.";
        Parse.Cloud.run('karmaTransaction', {
          userId: receivingUser.id,
          amount: -2,
          description: "Left a meeting undecided"
        }, null);
      }
      userMeeting.save({ active: false }, {
        success: function(userMeeting) {
          sendPushNotification(receivingUser, message, true, {
            success: function() {
              console.log("Sent a push notification to user " +
              receivingUser.id);
              response.success();
            },
            error: handleError
          });
        },
        error: function(userMeeting, error) {
          handleError(error);
        }
      });
    },
    error: handleError
  });
  function handleError(error) {
    response.error("An error occured while trying to send a push " +
      "notification to user " + receivingUser.id + ": " + error);
  }
}

function checkMeeting(meeting, response) {
  var endDate = meeting.get("date");
  endDate.setTime(endDate.getTime() + 60*60*1000);
  var now = endDate;//new Date();
  if (endDate <= now) {
    meeting.set("completed", true);
    meeting.save();
    var userMeetingQuery = new Parse.Query("UserMeeting");
    userMeetingQuery.equalTo("meeting", meeting);
    userMeetingQuery.find({
      success: handleUserMeetings,
      error: response.error
    });
  } else {
    response.success();
  }
  function handleUserMeetings(userMeetings) {
    var firstUser = userMeetings[0].get("user");
    var secondUser = userMeetings[1].get("user");
    sendSelfiePushNotification(firstUser, {
      success: function() {
        sendSelfiePushNotification(secondUser, {
          success: function() {
            console.log("Sent a push notification to user " + firstUser.id);
            console.log("Sent a push notification to user " + secondUser.id);
            response.success();
          },
          error: response.error
        });
      },
      error: response.error
    });
  }
}

function getMatchForUserIds(firstUserId, secondUserId, response) {
  var firstMatchQuery = new Parse.Query("Match");
  firstMatchQuery.equalTo("firstUser", firstUserId);
  firstMatchQuery.equalTo("secondUser", secondUserId);

  var secondMatchQuery = new Parse.Query("Match");
  secondMatchQuery.equalTo("secondUser", firstUserId);
  secondMatchQuery.equalTo("firstUser", secondUserId);

  var matchQuery = Parse.Query.or(firstMatchQuery, secondMatchQuery);
  matchQuery.first({
    success: function(match) {
      if (match) {
        saveMatchWithUserIds(match, firstUserId, secondUserId, response);
      } else {
        Parse.Cloud.run('saveMatch', {
          firstUserId: firstUserId,
          secondUserId: secondUserId
        }, response);
      }
    },
    error: function(error) {
      Parse.Cloud.run('saveMatch', {
        firstUserId: firstUserId,
        secondUserId: secondUserId
      }, response);
    }
  });
}

function saveMatchWithUserIds(match, firstUserId, secondUserId, response) {
  getUsersForIds(firstUserId, secondUserId, {
    success: function(firstUser, secondUser) {
      match.save({
        firstUser: firstUser,
        secondUser: secondUser,
        active: true
      }, {
        success: function(match) {
          firstUser.save({ activeMatch: match }, {
            success: function(firstUser) {
              secondUser.save({ activeMatch: match }, {
                success: function(secondUser) {
                  response.success(match);
                },
                error: function(secondUser, error) {
                  response.error(error);
                }
              });
            },
            error: function(firstUser, error) {
              response.error(error);
            }
          });
        },
        error: function(match, error) {
          response.error(error);
        }
      });
    },
    error: response.error
  });
}

function getUsersForIds(firstUserId, secondUserId, response) {
  var userQuery = new Parse.Query(Parse.User);
  userQuery.get(firstUserId, {
    success: function(firstUser) {
      userQuery.get(secondUserId, {
        success: function(secondUser) {
          response.success(firstUser, secondUser);
        },
        error: response.error
      });
    },
    error: response.error
  });
}

function findMatchForUser(user, response) {
  if (user.get("activeMatch")) {
    var matchQuery = new Parse.Query("Match");
    matchQuery.equalTo("active", true);
    matchQuery.get(user.get("activeMatch").id, {
      success: response.success,
      error: function(error) {
        response.error("No match found for user " + user.id);
      }
    });
  } else {
    response.error("No match found for user " + user.id);
  }
}

function saveCommonInterestsForMatch(match) {
  findInterestsForMatch(match, {
    success: function(interests) {
      console.log("Saved common user interests for match " + match.id);
      save(interests);
    },
    error: function(error) {
      save([]);
    }
  });
  function save(interests) {
    match.set("interests", interests);
    match.save();
  }
}

function findMeetingPlaceForMatch(match, response) {
  getMeetingPlacesIdsForUser(match.get("firstUser"), {
    success: function(firstUserMeetingPlacesIds) {
      getMeetingPlacesIdsForUser(match.get("secondUser"), {
        success: function(secondUserMeetingPlacesIds) {
          var commonMeetingPlacesIds = intersect(firstUserMeetingPlacesIds,
            secondUserMeetingPlacesIds);
          if (commonMeetingPlacesIds.length > 0) {
            var meetingPlaceQuery = new Parse.Query("MeetingPlace");
            meetingPlaceQuery.get(commonMeetingPlacesIds[0], {
              success: function(meetingPlace) {
                console.log("Common meeting place " + meetingPlace.id +
                " for match " + match.id);
                response.success(meetingPlace);
              },
              error: function(object, error) {
                handleError(null);
              }
            });
          } else {
            handleError(null);
          }
        }, error: handleError
      });
    }, error: handleError
  });
  function handleError(error) {
    randomMeetingPlaceForMatch(match, {
      success: function(meetingPlace) {
        console.log("Random meeting place " + meetingPlace.id + " for match " +
          match.id);
        response.success(meetingPlace);
      },
      error: function(error) {
        response.error("No meeting place found for match " + match.id);
      }
    });
  }
}

function getMeetingPlacesIdsForUser(user, response) {
  var userMeetingPlaceQuery = new Parse.Query("UserMeetingPlace");
  userMeetingPlaceQuery.equalTo("user", user);
  userMeetingPlaceQuery.find({
    success: function(userMeetingPlaces) {
      var meetingPlacesIds = [];
      for (var i = 0; i < userMeetingPlaces.length; i++) {
        meetingPlacesIds.push(userMeetingPlaces[i].get("meetingPlace").id);
      }
      response.success(meetingPlacesIds);
    },
    error: response.error
  });
}

function findTimeSlotForMatch(match, response) {
  getTimeSlotsIdsForUser(match.get("firstUser"), {
    success: function(firstUserTimeSlotsIds) {
      getTimeSlotsIdsForUser(match.get("secondUser"), {
        success: function(secondUserTimeSlotsIds) {
          var commonTimeSlotsIds = intersect(firstUserTimeSlotsIds,
            secondUserTimeSlotsIds);
          if (commonTimeSlotsIds.length > 0) {
            var timeSlotQuery = new Parse.Query("TimeSlot");
            timeSlotQuery.get(commonTimeSlotsIds[0], {
              success: function(timeSlot) {
                console.log("Common time slot " + timeSlot.id + " for match " +
                  match.id);
                response.success(timeSlot);
              },
              error: function(object, error) {
                handleError(null);
              }
            });
          } else {
            handleError(null);
          }
        }, error: handleError
      });
    }, error: handleError
  });
  function handleError(error) {
    randomTimeSlotForMatch(match, {
      success: function(timeSlot) {
        console.log("Random time slot " + timeSlot.id + " for match " +
        match.id);
        response.success(timeSlot);
      },
      error: function(error) {
        response.error("No time slot found for match " + match.id);
      }
    });
  }
}

function getTimeSlotsIdsForUser(user, response) {
  var userFreeTimeQuery = new Parse.Query("UserFreeTime");
  userFreeTimeQuery.equalTo("user", user);
  userFreeTimeQuery.find({
    success: function(userFreeTimes) {
      var timeSlotsIds = [];
      for (var i = 0; i < userFreeTimes.length; i++) {
        timeSlotsIds.push(userFreeTimes[i].get("timeSlot").id);
      }
      response.success(timeSlotsIds);
    },
    error: response.error
  });
}

function findInterestsForMatch(match, response) {
  getInterestsIdsForUser(match.get("firstUser"), {
    success: function(firstUserInterestsIds) {
      getInterestsIdsForUser(match.get("secondUser"), {
        success: function(secondUserInterestsIds) {
          if (!firstUserInterestsIds || !secondUserInterestsIds) {
            response.error(null);
          }
          var commonInterestsIds = intersect(firstUserInterestsIds,
            secondUserInterestsIds);
          if (commonInterestsIds.length > 0) {
            var interestQuery = new Parse.Query("Interest");
            interestQuery.containedIn("objectId", commonInterestsIds);
            interestQuery.find({
              success: response.success,
              error: response.error
            });
          } else {
            response.error(null);
          }
        }, error: response.error
      });
    }, error: response.error
  });
}

function getInterestsIdsForUser(user, response) {
  var userInterestQuery = new Parse.Query("UserInterest");
  userInterestQuery.equalTo("user", user);
  userInterestQuery.find({
    success: function(userInterests) {
      var interestsIds = [];
      for (var i = 0; i < userInterests.length; i++) {
        interestsIds.push(userInterests[i].get("interest").id);
      }
      response.success(interestsIds);
    },
    error: response.error
  });
}

function createUserMeetingsForMatch(match, meeting, response) {
  createUserMeetingForUser(match.get("firstUser"), meeting, {
    success: function(firstUserMeeting) {
      createUserMeetingForUser(match.get("secondUser"), meeting, {
        success: function(secondUserMeeting) {
          response.success([firstUserMeeting, secondUserMeeting]);
        }, error: response.error
      });
    }, error: response.error
  });
}

function createUserMeetingForUser(user, meeting, response) {
  var UserMeeting = Parse.Object.extend("UserMeeting");
  var userMeeting = new UserMeeting();
  userMeeting.save({
    user: user,
    meeting: meeting,
    hasSeen: false,
    hasAccepted: false,
    hasRejected: false,
    active: true
  }, {
    success: function(userMeeting) {
      user.save({
        hasMeetingScheduled: true,
        hasUndecidedMeeting: false,
      }, {
        success: function(user) {
          response.success(userMeeting);
        },
        error: function(user, error) {
          response.error(error);
        }
      });
    },
    error: function(userMeeting, error) {
      response.error(error);
    }
  });
}

function randomMeetingPlaceForMatch(match, response) {
  var users = [match.get("firstUser"), match.get("secondUser")];
  var randomUserIndex = Math.floor(Math.random()*users.length);
  var otherIndex = randomUserIndex === 0 ? 1 : 0;
  getMeetingPlacesForUser(users[randomUserIndex], {
    success: handleMeetingPlaces,
    error: tryOtherUser
  });
  function tryOtherUser(error) {
    getMeetingPlacesForUser(users[otherIndex], {
      success: handleMeetingPlaces,
      error: response.error
    });
  }
  function handleMeetingPlaces(meetingPlaces) {
    if (meetingPlaces.length > 0) {
      response.success(meetingPlaces[Math.floor(Math.random()*meetingPlaces.length)]);
    } else {
      response.error("No meeting place found for match " + match.id);
    }
  }
}

function getMeetingPlacesForUser(user, response) {
  var userMeetingPlaceQuery = new Parse.Query("UserMeetingPlace");
  userMeetingPlaceQuery.equalTo("user", user);
  userMeetingPlaceQuery.include("meetingPlace");
  userMeetingPlaceQuery.find({
    success: function(userMeetingPlaces) {
      var meetingPlaces = [];
      for (var i = 0; i < userMeetingPlaces.length; i++) {
        meetingPlaces.push(userMeetingPlaces[i].get("meetingPlace"));
      }
      response.success(meetingPlaces);
    },
    error: response.error
  });
}

function randomTimeSlotForMatch(match, response) {
  var users = [match.get("firstUser"), match.get("secondUser")];
  var randomUserIndex = Math.floor(Math.random()*users.length);
  var otherIndex = randomUserIndex === 0 ? 1 : 0;
  getTimeSlotsForUser(users[randomUserIndex], {
    success: handleTimeSlots,
    error: tryOtherUser
  });
  function tryOtherUser(error) {
    getTimeSlotsForUser(users[otherIndex], {
      success: handleTimeSlots,
      error: response.error
    });
  }
  function handleTimeSlots(timeSlots) {
    if (timeSlots.length > 0) {
      response.success(timeSlots[Math.floor(Math.random()*timeSlots.length)]);
    } else {
      response.error("No time slot found for match " + match.id);
    }
  }
}

function getTimeSlotsForUser(user, response) {
  var userFreeTimeQuery = new Parse.Query("UserFreeTime");
  userFreeTimeQuery.equalTo("user", user);
  userFreeTimeQuery.include("timeSlot");
  userFreeTimeQuery.find({
    success: function(userFreeTimes) {
      var timeSlots = [];
      for (var i = 0; i < userFreeTimes.length; i++) {
        timeSlots.push(userFreeTimes[i].get("timeSlot"));
      }
      response.success(timeSlots);
    },
    error: response.error
  });
}

function sendInvitationPushNotification(user, response) {
  sendPushNotification(user, "Вам пришло новое приглашение на встречу.", true,
  response);
}

function sendSelfiePushNotification(user, response) {
  var message = "Опубликуйте совместное селфи (+1 к карме).";
  user.save({
    canPostSelfie: true,
    lastNotification: message
  }, {
    success: function(user) {
      var installationQuery = new Parse.Query(Parse.Installation);
      installationQuery.equalTo('user', user);
      Parse.Push.send({
        where: installationQuery,
        data: {
          alert: message,
          badge: "Increment",
          reload: false
        }
      }, response);
    },
    error: function(user, error) {
      response.error(error);
    }
  });
}

function sendPushNotification(user, message, reload, response) {
  user.save({
    canPostSelfie: false,
    lastNotification: message
  }, {
    success: function(user) {
      var installationQuery = new Parse.Query(Parse.Installation);
      installationQuery.equalTo('user', user);
      Parse.Push.send({
        where: installationQuery,
        data: {
          alert: message,
          badge: "Increment",
          reload: reload
        }
      }, response);
    },
    error: function(user, error) {
      response.error(error);
    }
  });
}

/*
HELPERS
*/

function intersect(a, b) {
    var t;
    if (b.length > a.length) {
      t = b;
      b = a;
      a = t;
    }
    // indexOf to loop over shorter
    return a.filter(function (e) {
        if (b.indexOf(e) !== -1) return true;
    });
}

function getDateFromTimeSlot(timeSlot) {
  var weekday = timeSlot.get("weekday");
  weekday++;
  if (weekday == 7) {
    weekday = 0;
  }
  var hour = timeSlot.get("startingHour");
  var resultDate = new Date();
  resultDate.setDate(resultDate.getDate() +
    (7 + weekday - resultDate.getDay()) % 7);
  resultDate.setUTCHours(hour - 6, 0, 0, 0);
  return resultDate;
}

/*
VARIABLES
*/

var ruIndustries = {
  "1": "Оборонные и космические технологии",
  "3": "Компьютерная техника и комплектующие",
  "4": "Программное обеспечение",
  "5": "Компьютерное сетевое оборудование",
  "6": "Интернет-технологии",
  "7": "Полупроводниковые технологии",
  "8": "Телекоммуникации",
  "9": "Юридическая практика",
  "10": "Юридические услуги",
  "11": "Консалтинг в области управления",
  "12": "Биотехнологии",
  "13": "Медицинская практика",
  "14": "Больницы и медико-санитарная помощь",
  "15": "Фармацевтическая промышленность",
  "16": "Ветеринария",
  "17": "Медицинское оборудование",
  "18": "Парфюмерно-косметическая промышленность",
  "19": "Лёгкая промышленность и индустрия моды",
  "20": "Спортивные товары",
  "21": "Табачная промышленность",
  "22": "Розничная торговля потребительскими товарами",
  "23": "Пищевая промышленность",
  "24": "Бытовая техника и электроника",
  "25": "Потребительские товары",
  "26": "Мебельная промышленность",
  "27": "Розничная торговля",
  "28": "Развлечения",
  "29": "Азартные игры и казино",
  "30": "Путешествия, туризм и досуг",
  "31": "Гостиничное дело",
  "32": "Ресторанное дело",
  "33": "Спорт",
  "34": "Торговля продуктами питания",
  "35": "Кинематограф",
  "36": "Телевидение и радио",
  "37": "Музейное дело и охрана объектов культурного наследия",
  "38": "Изобразительное искусство",
  "39": "Театральное искусство",
  "40": "Отдых (услуги и учреждения)",
  "41": "Банковское дело",
  "42": "Страхование",
  "43": "Финансовые услуги",
  "44": "Недвижимость",
  "45": "Инвестиционно-банковская деятельность",
  "46": "Управление активами и инвестициями",
  "47": "Бухгалтерский учёт",
  "48": "Строительство",
  "49": "Строительные материалы",
  "50": "Архитектура и проектирование",
  "51": "Гражданское строительство",
  "52": "Авиационная и авиакосмическая промышленность",
  "53": "Автомобильная промышленность",
  "54": "Химическая промышленность",
  "55": "Двигателестроение и станкостроение",
  "56": "Горнодобывающая и металлургическая промышленность",
  "57": "Нефтяная и энергетическая промышленность",
  "58": "Судостроение",
  "59": "Коммунальные услуги",
  "60": "Текстильная промышленность",
  "61": "Лесная и целлюлозно-бумажная промышленность",
  "62": "Железнодорожная промышленность",
  "63": "Земледелие и растениеводство",
  "64": "Животноводство",
  "65": "Молочная промышленность",
  "66": "Рыбная промышленность",
  "67": "Начальное и среднее образование",
  "68": "Высшее образование",
  "69": "Управление образованием",
  "70": "Научно-исследовательская деятельность",
  "71": "Вооружённые силы",
  "72": "Законодательные органы",
  "73": "Судебные органы",
  "74": "Международные отношения",
  "75": "Правительственная администрация",
  "76": "Исполнительные органы",
  "77": "Правоохранительные органы",
  "78": "Национальная безопасность",
  "79": "Государственная политика",
  "80": "Маркетинг и реклама",
  "81": "Пресса",
  "82": "Издательское дело",
  "83": "Печатное дело",
  "84": "Информационные службы",
  "85": "Библиотечное дело",
  "86": "Охрана окружающей среды",
  "87": "Грузоперевозки",
  "88": "Социальная помощь и защита",
  "89": "Религиозные организации",
  "90": "Гражданские и общественные организации",
  "91": "Защита прав потребителей",
  "92": "Автомобильный и железнодорожный транспорт",
  "93": "Складское дело",
  "94": "Воздушный транспорт и авиалинии",
  "95": "Морской и речной транспорт",
  "96": "Информационные технологии и услуги",
  "97": "Маркетинговые исследования",
  "98": "Связи и взаимодействие с общественностью",
  "99": "Дизайнерское искусство",
  "100": "Управление некоммерческими организациями",
  "101": "Привлечение ресурсов на благотворительные нужды",
  "102": "Разработка планов и проектов",
  "103": "Литературный и редакторский труд",
  "104": "Кадровое обеспечение и подбор персонала",
  "105": "Профессиональное обучение и повышение квалификации кадров",
  "106": "Венчурный и частный капитал",
  "107": "Политические организации и объединения",
  "108": "Перевод и локализация",
  "109": "Интерактивные развлечения",
  "110": "Проведение праздников и мероприятий",
  "111": "Народное творчество и ремесла",
  "112": "Электрооборудование и электроника",
  "113": "Интернет-медиа",
  "114": "Нанотехнологии",
  "115": "Музыкальное искусство",
  "116": "Логистика и цепь поставок",
  "117": "Полимерная промышленность",
  "118": "Компьютерная и сетевая безопасность",
  "119": "Беспроводные технологии",
  "120": "Альтернативные методы разрешения споров",
  "121": "Корпоративная безопасность и расследования",
  "122": "Обслуживание офисного и промышленного оборудования",
  "123": "Привлечение внешних источников в деятельности предприятий",
  "124": "Здравоохранение и формирование здорового образа жизни",
  "125": "Альтернативная медицина",
  "126": "Медиапроизводство",
  "127": "Анимация",
  "128": "Коммерческая недвижимость",
  "129": "Рынки капитала",
  "130": "Научно-исследовательские центры",
  "131": "Благотворительность",
  "132": "Дистанционное обучение",
  "133": "Оптовая торговля",
  "134": "Импорт и экспорт потребительских товаров",
  "135": "Машиностроение и производственная инженерия",
  "136": "Фотографическое искусство",
  "137": "Кадровое сопровождение",
  "138": "Офисные товары и оборудование",
  "139": "Охрана психического здоровья",
  "140": "Графический дизайн",
  "141": "Международное сотрудничество и развитие",
  "142": "Алкогольная продукция",
  "143": "Ювелирная промышленность",
  "144": "Экология производства и возобновляемая энергетика",
  "145": "Стекольная, керамическая и бетонная промышленность",
  "146": "Упаковочная промышленность",
  "147": "Автоматизация производства",
  "148": "Лоббирование бизнеса в государственных органах"
};

var enIndustries = {
  "1": "Defense & Space",
  "3": "Computer Hardware",
  "4": "Computer Software",
  "5": "Computer Networking",
  "6": "Internet",
  "7": "Semiconductors",
  "8": "Telecommunications",
  "9": "Law Practice",
  "10": "Legal Services",
  "11": "Management Consulting",
  "12": "Biotechnology",
  "13": "Medical Practice",
  "14": "Hospital & Health Care",
  "15": "Pharmaceuticals",
  "16": "Veterinary",
  "17": "Medical Devices",
  "18": "Cosmetics",
  "19": "Apparel & Fashion",
  "20": "Sporting Goods",
  "21": "Tobacco",
  "22": "Supermarkets",
  "23": "Food Production",
  "24": "Consumer Electronics",
  "25": "Consumer Goods",
  "26": "Furniture",
  "27": "Retail",
  "28": "Entertainment",
  "29": "Gambling & Casinos",
  "30": "Leisure, Travel & Tourism",
  "31": "Hospitality",
  "32": "Restaurants",
  "33": "Sports",
  "34": "Food & Beverages",
  "35": "Motion Pictures and Film",
  "36": "Broadcast Media",
  "37": "Museums and Institutions",
  "38": "Fine Art",
  "39": "Performing Arts",
  "40": "Recreational Facilities and Services",
  "41": "Banking",
  "42": "Insurance",
  "43": "Financial Services",
  "44": "Real Estate",
  "45": "Investment Banking",
  "46": "Investment Management",
  "47": "Accounting",
  "48": "Construction",
  "49": "Building Materials",
  "50": "Architecture & Planning",
  "51": "Civil Engineering",
  "52": "Aviation & Aerospace",
  "53": "Automotive",
  "54": "Chemicals",
  "55": "Machinery",
  "56": "Mining & Metals",
  "57": "Oil & Energy",
  "58": "Shipbuilding",
  "59": "Utilities",
  "60": "Textiles",
  "61": "Paper & Forest Products",
  "62": "Railroad Manufacture",
  "63": "Farming",
  "64": "Ranching",
  "65": "Dairy",
  "66": "Fishery",
  "67": "Primary/Secondary Education",
  "68": "Higher Education",
  "69": "Education Management",
  "70": "Research",
  "71": "Military",
  "72": "Legislative Office",
  "73": "Judiciary",
  "74": "International Affairs",
  "75": "Government Administration",
  "76": "Executive Office",
  "77": "Law Enforcement",
  "78": "Public Safety",
  "79": "Public Policy",
  "80": "Marketing and Advertising",
  "81": "Newspapers",
  "82": "Publishing",
  "83": "Printing",
  "84": "Information Services",
  "85": "Libraries",
  "86": "Environmental Services",
  "87": "Package/Freight Delivery",
  "88": "Individual & Family Services",
  "89": "Religious Institutions",
  "90": "Civic & Social Organization",
  "91": "Consumer Services",
  "92": "Transportation/Trucking/Railroad",
  "93": "Warehousing",
  "94": "Airlines/Aviation",
  "95": "Maritime",
  "96": "Information Technology and Services",
  "97": "Market Research",
  "98": "Public Relations and Communications",
  "99": "Design",
  "100": "Nonprofit Organization Management",
  "101": "Fund-Raising",
  "102": "Program Development",
  "103": "Writing and Editing",
  "104": "Staffing and Recruiting",
  "105": "Professional Training & Coaching",
  "106": "Venture Capital & Private Equity",
  "107": "Political Organization",
  "108": "Translation and Localization",
  "109": "Computer Games",
  "110": "Events Services",
  "111": "Arts and Crafts",
  "112": "Electrical/Electronic Manufacturing",
  "113": "Online Media",
  "114": "Nanotechnology",
  "115": "Music",
  "116": "Logistics and Supply Chain",
  "117": "Plastics",
  "118": "Computer & Network Security",
  "119": "Wireless",
  "120": "Alternative Dispute Resolution",
  "121": "Security and Investigations",
  "122": "Facilities Services",
  "123": "Outsourcing/Offshoring",
  "124": "Health, Wellness and Fitness",
  "125": "Alternative Medicine",
  "126": "Media Production",
  "127": "Animation",
  "128": "Commercial Real Estate",
  "129": "Capital Markets",
  "130": "Think Tanks",
  "131": "Philanthropy",
  "132": "E-Learning",
  "133": "Wholesale",
  "134": "Import and Export",
  "135": "Mechanical or Industrial Engineering",
  "136": "Photography",
  "137": "Human Resources",
  "138": "Business Supplies and Equipment",
  "139": "Mental Health Care",
  "140": "Graphic Design",
  "141": "International Trade and Development",
  "142": "Wine and Spirits",
  "143": "Luxury Goods & Jewelry",
  "144": "Renewables & Environment",
  "145": "Glass, Ceramics & Concrete",
  "146": "Packaging and Containers",
  "147": "Industrial Automation",
  "148": "Government Relations"
};
