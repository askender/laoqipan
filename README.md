# Laoqipan

This is the source code for [laoqipan.com](http://laoqipan.com), a site for playing the board game Go online with other players around the world or against the computer: GNUGO.

If you have suggestions or questions, please post them on the [Issue Tracker](https://github.com/imonyse/laoqipan/issues).

## Setup

### Software Requirements
+ A HTML5 canvas api supported browser 
+ ruby 1.9.2
+ [rvm](http://beginrescueend.com/) (optional)
+ postgresql >= 8.3 (Make sure your current user have the createdb privilege)
+ [redis](http://redis.io/) (needed by juggernaut)
+ [juggernaut](https://github.com/maccman/juggernaut) (make sure redis-server is started before you run juggernaut)
+ [beanstalk](http://kr.github.com/beanstalkd/) (make sure beanstalkd is started, if not, run 'beanstalkd -d')
+ [gnugo](http://www.gnu.org/s/gnugo/download.html) (Gnugo is used for calculate final score and playing with computer)

When you have all the software above installed, make some necessary changes to config/database.example.yml, then follow the instructions below:

<pre>
bundle
cp config/database.example.yml config/database.yml
cp config/private.example.yml config/private.yml
cp config/cronjob.example config/cronjob
rake db:create db:migrate
</pre>

Type 'script/worker development' to start a gnugo worker(so you can play with gnugo and calculate final score), then type 'juggernaut' to start juggernaut server. Then start the development server with 'rails s'. 

Chinese is the default language, but you can easily switch to English by clicking the 'English Version' link on the website.

## Contributing
I maintain this site for my personal hobby and entertainment. So, currently I *DO NOT* accept features pull request except language correction to 'config/local/en.yml', as English is not my native speaking language.

If you feel really necessary to submit a patch to me, please follow the instructions below:

### Creating and Submitting a Patch
If you feel really necessary to submit a patch, I prefer that you send a [pull request](http://help.github.com/pull-requests/) on GitHub.

1. Create a fork of the upstream repository by visiting <https://github.com/imonyse/laoqipan/fork>. If you feel insecure, here's a great guide: <http://help.github.com/forking/>

2. Clone your repository to a local copy: `git clone https://yourusername@github.com/yourusername/laoqipan.git`

3. This is important: Create a so-called *topic branch*: `git checkout -tb name-of-my-patch` where "name-of-my-patch" is a short but descriptive name of the patch you're about to create. Don't worry about the perfect name though -- you can change this name at any time later on.

4. Hack! Make your changes, additions, etc and commit them.

5. Run 'rake test', make sure all the tests for server get passed. 

6. Run 'rails s' if you haven't done already. Now go to 'http://localhost:3000/jasmine', make sure all tests get green.

7. Send a pull request to the upstream repository's owner by visiting your repository's site at github (i.e. https://github.com/yourusername/laoqipan) and press the "Pull Request" button. Here's a good guide on pull requests: <http://help.github.com/pull-requests/>

**Use one topic branch per feature** -- don't mix different kinds of patches in the same branch. Instead, merge them all together into your master branch (or develop everything in your master and then cherry-pick-and-merge into the different topic branches). Git provides for an extremely flexible workflow, which in many ways causes more confusion than it helps you when new to collaborative software development. The guides provided by GitHub at <http://help.github.com/> are a really good starting point and reference.
If you are fixing a ticket, a convenient way to name the branch is to use the URL slug from the bug tracker, like this: `git checkout -tb 53-feature-manually-select-language`.

## Credits
Much of the work could not be done without watching [Ryan Bates](https://github.com/ryanb)' amazing [rails casts](http://railscasts.com).