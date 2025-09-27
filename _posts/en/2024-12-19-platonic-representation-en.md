---
title: "Fragment: The Platonic Representation Hypothesis"
date: 2024-12-19
categories: [The Road Ahead for Science]
tags: [Philosophy, Science]
description: A paper I stumbled across that resonates with some of my own thoughts
lang: en
original_slug: 2024-12-19-platonic-representation
translated: true
---

> Before reading this post, I hope the reader will take a look at [About](/about) to better understand the positioning of this blog.  
{: .prompt-info }

What a coincidence! Zhihu happened to recommend me an article whose ideas partially overlap with mine: [The Platonic Representation Hypothesis](https://arxiv.org/abs/2405.07987).  

> The paper reports experimental findings that, as neural networks and datasets scale up, the way networks represent the world shows a convergent trend across different architectures and data modalities. Based on this, the authors propose the *Platonic Representation Hypothesis*: namely, that neural networks trained on different tasks, datasets, and modalities converge toward a common statistical model of reality. They call this the “platonic representation,” likening it to Plato’s ideal reality.

At present, I see two possible routes for AI for Science:

- **Approximation of existing human cognitive systems**:  
  Examples include facial recognition, GPT, etc. Here, model evaluation depends not only on observations of the world but also on the structure of human cognition already in place.  

- **Direct modeling of the world itself**:  
  Here, model evaluation depends solely on observed phenomena—starting modeling from the phenomena themselves and trying, as far as possible, to minimize the influence of preexisting cognition (though avoiding it completely seems impossible).  

(It feels like these two approaches might loosely correspond to Kant’s *synthetic a priori judgments* and phenomenology? But I haven’t studied them closely yet—just a preliminary impression.)  

In practice, there’s no strict boundary between the two paths. It’s only in the limit that the difference becomes clear. For example, when taking the second route, we might still use parameters obtained from the first route as initialization for training.  

From my perspective, the findings of this paper can be understood in terms of the first path: they approximate human cognition. But instead of converging to a single clear limit, they should converge within a range, since human cognition is both fuzzy and dynamically evolving—though there may be some relatively stable parts. As for whether the second path has a true limit… well, that probably depends on luck.  

In the paper, the authors seem inclined to think that both our observations and the state of reality are just “samples” from some probability model—something akin to Plato’s ideal reality[^1]. See footnote 4 on page 7 of the paper:  

> “This latter interpretation may be more consistent with Plato’s intent. Scholars have argued that his allegory of the cave rejects any notion of a true world state (Nettleship, 1897). Instead, we could say that the joint distribution of observation indices is itself the *platonic reality*.”  

[^1]: I’m not familiar enough with Plato to be sure I’ve fully grasped the authors’ meaning here.  
