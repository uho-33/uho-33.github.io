---
title: Doubting Science
date: 2024-11-27
categories: [The Road Ahead for Science]
tags: [Philosophy, Science]
description: A brief introduction to why I’ve come to doubt science, and why I’m moving toward AI for Science / AI for World Cognition
lang: en
original_slug: 2024-11-29-doubt-science
translated: true
---

> Before reading this post, I hope the reader will take a look at [About](/about) to better understand the positioning of this blog.  
{: .prompt-info }

At the moment, my view of science is still in a state of confusion. I feel a mix of doubt, helplessness, and estrangement toward it.  

In the past, I believed that science (or physics) was absolutely objective—that it could reveal the true face of the world, and that almost any problem could be reduced to a scientific one and solved rigorously. But over the past two years, philosophy has awakened me from a near-fanatical superstition in science and its powers.

In this post, I’ll briefly introduce a few philosophical ideas that have influenced my thinking. I won’t go into their technical details here; if readers want to explore further, you can consult [Zhihu](https://www.zhihu.com), or the [Stanford Encyclopedia of Philosophy](https://plato.stanford.edu/index.html). I’ll also place links to relevant SEP entries in the footnotes.  

## Hume’s Problem[^1]: Doubt about the Existence and Knowability of Necessity

Hume’s problem is skepticism about inductive reasoning, which can extend to skepticism about causality.  

Put simply, Hume’s problem states that inductive reasoning cannot guarantee the necessity of its conclusions. What we derive from experience cannot guarantee truth beyond experience (for example, the fact that the sun has always risen in the east does not guarantee that it must rise there tomorrow). But science’s aim is precisely to discover necessity in experience, so Hume’s problem calls science itself into question.  

This skepticism has two aspects:  

1. Does necessity really exist?  
2. If necessity does exist, how can we ever know that we’ve recognized it?  

That experience cannot guarantee conclusions beyond itself undermines our ability to assert the existence of necessity. It may be that necessity does not exist at all—that all the so-called ‘laws’ we have discovered may turn out to be accidental, collapsing in the very next moment—at which point even ‘I’ might cease to exist.

Suppose we take the optimistic view and believe some kind of necessity exists. Then how do we know we’ve actually recognized it? Hume’s problem again denies us this. Even if we happen to stumble upon necessity, we can’t be sure it *is* necessity—we discover it via necessary conditions of necessity, but those conditions don’t suffice to guarantee it be necessity. (For instance, a necessary condition for something being liquid water is that it is in a liquid state. But being liquid doesn’t guarantee it’s water—it could just as well be gasoline, alcohol, etc.)  

Hume’s problem suggests that science may be a gamble—one doomed to fail, without an endpoint.  

## The Duhem-Quine Thesis[^2]: The Non-Falsifiability of Unobservable Claims

If Hume’s problem denies our ability to assert what the world *is* (sufficient conditions), might we still be able to assert what the world *isn’t* (necessary conditions)? The Duhem-Quine thesis partly denies this possibility too. Observable claims can be falsified when they clash with experience. But unobservable claims cannot.  

In short, the Duhem-Quine thesis says that scientific hypotheses cannot be tested in isolation; experiments test entire theories as wholes.  

Why? Because theories contain both observable and unobservable parts (and this distinction isn’t just due to incidental factors like measurement precision—it can be rooted in the theory itself[^3]). To test unobservable claims ($A$), we must derive observable consequences ($B$). But $A$ alone cannot yield $B$; we need auxiliary assumptions ($E$). So when experiment contradicts $B$, all we know is that *either* $A$ or $E$ is problematic—but we can’t tell which.  

This leads to a consequence: unobservable assumptions in a theory can almost always be protected from falsification by adjusting other parts of the theory. For example, when global warming predictions clash with observed local cooling, we don’t abandon the greenhouse effect hypothesis; instead, we modify factors like aerosols or local conditions to reconcile the contradiction.  

Thus the Duhem-Quine thesis denies us the ability to falsify unobservable claims. Taken together with Hume’s problem, it denies us the ability to judge the truth or falsity of such claims at all.  

So what, then, is left of science?  

## The Road Ahead for Science

If we still want to continue this gamble called science, two paths remain: regulate scientific practice, or adjust science’s goals[^4].  

**The first path** is represented by Imre Lakatos’s *Scientific Research Programs*[^5]. By analyzing the history of science, he distilled a set of norms for scientific research. If the aim is simply to keep doing something called “science,” this path works.  

But personally, I don’t want to do science merely for its own sake. I want science to aim at something. And the norms offered by the first path don’t guarantee that. That’s why I lean toward the second path.  

**The second path** is represented by Bas van Fraassen’s *Constructive Empiricism*[^6]. Here, the goal is to redefine science’s aspirations in a way that doesn’t demand too much revision of our original expectations.  

Hume’s problem denies us the ability to positively affirm necessity. The Duhem-Quine thesis denies us the ability to falsify unobservable claims. What remains is the ability to falsify *observable* claims. Thus, the most cautious expectation we can hold for science is correctness in the observable domain. While we can’t guarantee necessity even here, we can still use falsification to inch closer to theories that might be necessarily true.  

From this perspective, the aim of scientific practice is *empirical adequacy*—agreement with the observable domain. When we accept a theory, our commitment is only that it’s correct about observables, not that its unobservable entities really exist. We may by chance get the unobservables right, but pursuing such unverifiable hopes only distracts science.  

To fully test a theory’s empirical adequacy, we need to integrate all domains of human cognition, since science is not isolated from them. Human cognition as a whole—the “web of belief”—connects to the observable world. Physics, for example, relies on logic, biology, geology, and more to yield observable predictions. In the end, what we are really building is humanity’s cognition of the observable world. It’s not limited to any one discipline or method—what matters is simply whether its conclusions match experience in the observable domain.  

One possible path to this goal is AI. I call this **AI for World Cognition**, or **Holistic World AI**[^7].  

Under this view, we can also respond to some doubts about applying AI in science. To keep this post concise, I’ve placed those responses in the appendix.  

## Afterword

I expect to write more on AI for World Cognition in the future, though the timeline is uncertain—I want to let my thoughts settle further.  

It doesn’t really feel like I’ve chosen this path out of passion or some lofty ideal. In a sense, it’s more like just finding something to do—*“simply choosing a hell I can live with”*[^8].  

---

## Appendix: Replies to Doubts About AI in Science

1. **Sometimes machine learning performs worse than traditional theories.**  
   On the one hand, learning strategies and model architectures can certainly be improved. On the other, we should realize that machine learning models are usually trained on limited datasets, whereas traditional theories have been shaped by nearly all human observations and by natural selection’s long filtering of initial conditions. If we had built traditional theories using only the limited data available to train ML models, they might not have outperformed ML either.  

2. **Machine learning is a “black box.”** Two common reasons for this claim:  
   1. **ML doesn’t spell out causal details the way traditional theories do** (e.g., a theory can describe the process from striking a match to producing a flame, while ML only predicts the flame will appear).  
      But this gap mainly reflects current model design goals, not an essential flaw of ML. Consider models like ChatGPT, which can articulate processes in theory-like ways, describing what happens between phenomena.  
   2. **We don’t know why ML gives the conclusions it does (poor interpretability).**  
      If “interpretability” means reconstructing the input-output process using existing human logic and language, then yes, this is a challenge. But if the aim of science is empirical adequacy (or even “truth”), then aside from practical convenience, there’s no reason to insist on interpretability. After all, we can’t be sure human reasoning procedures are guaranteed to achieve our goals—or to be the best way to achieve them. (Yet another implication of Hume’s problem.)  

---

## Footnotes

[^1]: [The Problem of Induction (Stanford Encyclopedia of Philosophy)](https://plato.stanford.edu/entries/induction-problem/)  
[^2]: [Underdetermination of Scientific Theory (Stanford Encyclopedia of Philosophy)](https://plato.stanford.edu/entries/scientific-underdetermination/)  
[^3]: For example, in Newtonian mechanics the mass of an isolated body cannot be determined—mass only manifests in interactions. Thus the claim “the mass of an isolated body is $1 \, \mathrm{kg}$” cannot be judged true or false. Another example is quark confinement in particle physics.  
[^4]: There may also be other paths—for instance, abandoning the boundary of “science” altogether and treating all human cognition as one whole, focusing only on accumulation.  
[^5]: [Imre Lakatos (Stanford Encyclopedia of Philosophy)](https://plato.stanford.edu/entries/lakatos/#ImprPoppScie)  
[^6]: [Constructive Empiricism (Stanford Encyclopedia of Philosophy)](https://plato.stanford.edu/entries/constructive-empiricism/)  
[^7]: I avoid the name *AI for Science* because my vision differs from the usual sense of that term. In common usage, AI for Science means applying AI *within* the framework of science. The system I imagine, however, is positioned on par with the whole of human cognition itself, standing as an equal alongside science.  
[^8]: From *Blue Period*, chapter 69. A surprisingly inspiring manga—highly recommended!  
