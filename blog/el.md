# El Shell

This project just jumped ahead in the post queue and the WIP column. Despite my previous post, I was not planning on making any shell for the Dude. Claude Code itself is a shell, typescripted over Node.js. And that's the problem, the Dude was trapped on a one-trick pony of a shell.

Everybody is building agent orchestrations right now. Mine is the Dude, and it's full of loops. The discovery one uses a game called 3 Amigos. The amigos could not be just subagents, they needed context to iterate. For that, Claude Code is making agent teams.

Agent teams feel so buggy right now. I might be hating, but saving to an inbox.json file and having a watcher on it is pretty flaky. The Dude struggles to start the team, gets anxiety when they go idle. I keep patching it and figuring it out. I know that Anthropic is going to get it to work at some point. But it could be so much simpler in, errr, Erlang?

## Eleven

The idea is, instead of inventing a Flintstones version of a messaging platform, let's use one that already exists for the Dude. The Dude needs a phone, and Ericsson, the makers of Erlang, solved that problem in the '80s. Elixir added a Ruby-like shell around it, and that in part explains why El.

I've been building Elita for a little while. Elita is a very ambitious agentic platform I'm making. Because everybody is making one of those too. The impossibility of Dudes talking to each other is solved naturally in Elita. So before getting all deep into that, I saw an opportunity for a smaller Elita. Maybe just El would do.

Scanners was the name I had in mind. Some obscure TV series from the '80s with people with mental powers. Because that's the type of communication I'm expecting to have, so natural that it feels mental, telepathic. I asked the Dude about a more current reference with the same vibes for a TV show. He came back with Eleven, aka El, from Stranger Things.

## El Zombie

The first usage of El is headless. These are Dudes without a shell. In team terms, they are equivalent to in-process teammates in the sense that you don't see them. In El they are called zombies, and you can start one by entering `el zombie &` on the shell.

What makes it a zombie is not the name. The name is what you use to talk to it later. What makes it a zombie is the `&` at the end. With the `&`, the Dude runs in the background without a shell.

Now with a zombie afoot you can `el zombie ask what do u want` or `el zombie tell brainnnss`. Use tell when no response is wanted. You can inspect zombies with `el ls` or `el zombie log`. Ultimately you can `el zombie kill` or `el kill all`.

## El Dude

I had no zombie mode in mind. I expected El to just magically make any Dude able to talk to another. But then the shell was in the way. The Dude right now runs in the shell and wrapping it in El made it lose its shell. That's when I understood that El is a shell around another.

El by design allows you to use OTP patterns to communicate across Dudes in the same machine. OTP also brings supervision trees and a myriad of tools to enhance reliability. By being a shell around another it also allows a higher layer of metaprogramming. It allows more easily the Dude to Dude itself.

I know I am maniacal, who am I to enter a horse race with Anthropic. They are gonna keep bolting enough messaging patterns in that pony until it becomes Pegasus. I might be just impatient or maybe I just did cut that Gordian knot.

El took less than 1 hr to POC, 1 weekend to bootstrap, 48 hours to be done. Now the Dude can do actual teamwork. I also found a new layer where I can puppeteer from. The Dude has a new Iron Man suit, transparent as the emperor's clothes. You can `brew install` it on your shell and then summon `el dude`'s ghost.
