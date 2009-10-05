Stories Sync
============

The idea behind this gem is to have a tool to help you manage your user stories.

It'a a great combo to use [stories](github.com/citrusbyte/storires) + [Pivotal Tracker](http://www.pivotaltracker.com) for your integration testing, and it works pretty fine out of the box. However, one can't avoid thinking that there's something missing. For example there's no obvious way to run your user stories or generate reports easily; one would have to create a rake task or something like that.

And what about the ability to have pending stories? seems like a cool idea, but for that to make any sense, one would have to copy/past every story (one by one) on your backlog at the beginning of each sprint to your local stories file, mark them as pending stories and start them one at a time. Seems like a lot of work. It is.

Finally, if you discover that a story actually needs to be splitted in two, or you just want to add a new story and start implementing it, it's kind of a drag to have to log in to pivotal, create the story, move it to the backlog, mark it as "started", then go back to your local file, copy it there and finally start coding.

What we wanted is the following workflow:

    $ stories sync

That's it. That simple command will fetch the pivotal stories and add them as pending stories in your file and also upload any new local story to pivotal.

If you want to run your stories with the standard stories output:

    $ stories run

To generate a pdf report:

    $ stories report


Setup and usage
---------------

This gem requires you to have a pivotal.yml in your config directory, but this can be generated automatically. Just execute the following:

    $ stories setup

This will ask you for your pivotal username and password, then it will fetch your api token and finally it will create a config file for you.
After that you are all set. You just need to have a stories file in /test/stories/stories.rb.

_Right now this gem supports a single stories file only. This is the first version though, we are working for multiple file support._
