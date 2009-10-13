Stories Sync
============

The idea behind this gem is to have a tool to help you manage your user stories.

It'a a great combo to use [stories](http://github.com/citrusbyte/stories) + [Pivotal Tracker](http://www.pivotaltracker.com) for your integration testing, and it works pretty fine out of the box. However, one can't avoid thinking that there's something missing. For example there's no obvious way to run your user stories or generate reports easily; one would have to create a rake task or something like that.

And what about the ability to have pending stories? seems like a cool idea, but for that to make any sense, one would have to copy/paste every story (one by one) on your backlog at the beginning of each sprint to your local stories file, mark them as pending stories and start them one at a time. Seems like a lot of work. It is.

Finally, if you discover that a story actually needs to be splitted in two, or you just want to add a new story and start implementing it, it's kind of a drag to have to log in to pivotal, create the story, move it to the backlog, mark it as "started", then go back to your local file, copy it there and finally start coding.

What we wanted is the following workflow:

    $ stories sync

That's it. That simple command will fetch the pivotal stories and add them as pending stories in your file and also upload any new local story to pivotal.

If you want to run your stories with the standard stories output:

    $ stories run

To generate a pdf report:

    $ stories report


Setup and usage
===============

Installation
------------

    $ gem sources -a http://gemcutter.org
    $ gem install stories_sync

This gem requires you to have a pivotal.yml in your config directory, but this can be generated automatically. Just execute the following at the root of your project:

    $ stories setup

This will ask you for your pivotal username and password, then it will fetch your api token and create a config file for you.

Usage example
-------------

To make things clearer, here's an example of a project that has two different test files (test/stories/users_test.rb and test/stories/admins_test.rb) and we want to keep it in sync with our Pivotal project.

Lets suppose we are beginning a new sprint and so we add more stories to the backlog. For example,

With the label "users":

    As a user I want to log in so that I can start using my app
    As a user I want to log out so that I can stop using my app

with the label "admins":

    As an admin I want to log in so that I can start managing users

Now we want to start coding and have those stories in our files, marked as pending. We can execute the sync command at the root of our project:

    $ stories sync

Now our users tests file will look something like this:

    ...

      # Pending stories:

      story "As a user I want to log in so that I can start using my app"
      story "As a user I want to log out so that I can stop using my app"

    end

The same goes for the admins test file.

If later we add a new story in users_test.rb we can run the sync command again and it will upload it to pivotal (to the backlog) with the label "users".
