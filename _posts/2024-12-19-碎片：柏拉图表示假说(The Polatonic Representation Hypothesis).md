---
title: 碎片：柏拉图表示假说(The Polatonic Representation Hypothesis)
date: 2024-12-19
categories: [科学的前路]
tags: [哲学, 科学]
description: 偶然发现的一篇与我看法有相似之处的实验文章
---

> 在阅读本文前，希望读者能阅读[关于](/about)理解本博客定位
{: .prompt-info }

!!!好巧!知乎推了一篇想法与我有部分相似的文章：[The Platonic Representation Hypothesis](https://arxiv.org/abs/2405.07987)

> 该文通过实验研究发现，随着神经网络和数据规模的增大，网络在不同架构和数据模态下对世界的表达方式呈现出一种跨网络架构和跨数据模态的收敛趋势。基于这一现象，作者提出了柏拉图表示假说（The Platonic Representation Hypothesis），认为在不同任务、不同数据集以及不同数据模态下训练的神经网络，其表示空间会收敛于一个共同的现实的统计模型，作者称其为”柏拉图表示“(platonic representation)，认为是与柏拉图的理想现实(ideal reality)相似的东西。

我目前的看法是，AI for Science 有两条进路：

- **对人类已有认知体系的近似**：  
    例子如：人脸识别、GPT等。这一路径的特点在于，对模型好坏的评估并非仅依赖于对世界的观测，还依赖于人类已有认知体系。
    
- **直接对世界的建模**：  
    这一路径的特点在于，能对模型作出评价的只有观察到的现象，从现象本身出发进行建模，尽可能地避开已有认知的影响（完全避开似乎是不可能的）。
    

（这二者似乎可以分别与康德的先天综合判断和现象学扯上关系？不过这两我还没具体了解，只是点初步的感觉）

实践中，这二者似乎并无严格的界限，只是在极限下看起来有显著差异。如采用第二条路时，我们可以将由第一条路得到的参数作为初始化条件进行模型的训练。

在我的观点下，该文的发现可以在第一条路径下得到理解，它逼近的是人类认知体系，但并非有明确的极限，应该是一个范围，因为人类认知体系存在模糊性且会动态变化，但或许会存在一些相对固定的部分。而第二条路径是否真的存在极限就要看人类的运气了吧（

在该文中，作者似乎倾向于认为我们的观测以及现实的状态都是某个概率模型的“采样”，类似于柏拉图的理想现实？[^1] 参见原文 p. 7 脚注 4：

> “This latter interpretation may be more consistent with Plato’s intent. Scholars have argued that his allegory of the cave rejects any notion of a true world state (Nettleship, 1897). Instead, we could say that the joint distribution of observation indices is itself the *platonic reality*.” 

[^1]: 我暂时不了解柏拉图的东西，不太确定是否理解对作者想法