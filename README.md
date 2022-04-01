# faceSwapAugmentation
## Goal of this project
The goal of this project is to build a reliable data augmentation system,
which will allow the user to create an unlimited number of face-swapped video clips, based on
a single starting video.
This method can be applied in every field which requires a large
amount of data.

## Pipeline architecture
The pipeline takes as input video `data_dst.mp4`, which will be used as
a base upon which apply a face. This face can be generated by AI, in
two different methods: [stylegan2](https://github.com/NVlabs/stylegan2-ada-pytorch/), or [ThisPersonDoesNotExist](https://this-person-does-not-exist.com/it).

The to-be-applied faces can also be gathered from a dataset. To this
matter, `KDEF face dataset` is the suggested dataset (that can be downloaded [here](https://www.kdef.se/home/aboutKDEF.html)), but many others can be used.

The obtained results will strongly rely on two factors:
- Emotional variance of the source images
- Angle variance of the source images

The former is essential to achieve realistic face muscle motion and
expressions, the latter is fundamental in oder to obtain a face swap
even when the pose reaches extreme angles.
![Pipeline Structure](mdimgs/PipelineStructure.drawio.png "Pipeline
Structure")

## Installation and setup
Virual environments are managed with 
[Conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/).
There are several virtual environments that are necessary for the
whole pipeline. A `.yml` file for each one of those can be found under the
`envs` folder.
To create an environment from a `.yml` file, type:
`conda env create -f environment.yml`. This command must be run for
each file in the `envs` folder.

***Important: clone this repository with the following command in
order to clone all the submodules***
```
git clone --recurse-submodules https://github.com/leno3003/faceSwapAugmentation

```
**Check all the submodule's repositories for further instructions
about the installation of each and single element of the pipeline.**

Once done that, 
```
cd DeepFaceLab_Linux
```
and
```
git clone https://github.com/leno3003/DeepFaceLab.git
```
---
In order to use `KDEF` as face dataset, it must be placed in the
`faceSwapAugmentation` directory, as such:
```
.
├── Deep3DFaceRecon_pytorch
├── DeepFaceLab_Linux
├── ***KDEF_and_AKDEF***
├── README.md
├── ThisPersonDoesNotExistAPI
├── TransformMeshToGIFSprite
├── framesEvaluation.py
├── lmDeep3DFR.py
├── pipelineAutomation.sh
├── stylegan2-ada-pytorch
└── swapQualityEvaluation

```
## Usage

The pipeline takes as input a video, called `data_dst.mp4`. This will
be the base video, upon which AI generated faces will be applied. All
the facial variations, emotions and expressions will be kept in the
resulting video. 

Other than `data_dst.mp4`, the pipeline takes in
input a second argument, `-s`, which can be choosen from one of the
following:
- stylegan
- tpdne
- whole
- <path_to_imgs> (a folder with images in it)

Choosing `stylegan`, the pipeline will generate a face using
[stylegan2-ada-pytorch](https://github.com/NVlabs/stylegan2-ada-pytorch/)
Example:
`./pipelineAutomation.sh -s stylegan -d test.mp4`

Choosing `tpdne`, the pipeline will generate a face using
[ThisPersonDoesNotExistAPI](https://github.com/David-Lor/ThisPersonDoesNotExistAPI)
Example:
`./pipelineAutomation.sh -s tpdne -d test.mp4`

Choosing `whole`, will be produced a face-swap video for each
individual in the `KDEF_and_AKDEF/KDEF/` folder.
Example:
`./pipelineAutomation.sh -s whole -d test.mp4`

Passing as `-s` argument a path to a folder, all the images in it will
be used in order to create the face swap video.
Example:
`./pipelineAutomation.sh -s img_folder/ -d test.mp4`

Generic usage:
`./pipelineAutomation.sh -s <src_choice_or_path> -d <dst_path>`

## Automation of the Pipeline

Since `DeepFaceLab` is composed of several scripts, each of them
requiring human interaction in order to acquire the user's preferences about execution
parameters, some changes have been made to the default
DeepFaceLab's repository code.

By runnning in the `faceSwapAugmentation` directory:
```
python DeepFaceLab_Linux/DeepFaceLab/core/interact/no_interact_dict.py
```
the `interact_dict.pkl` file will be generated in the
`DeepFaceLab_Linux/workspace/interact` folder. This pickle file will
contain a dictionary of choices that will automatically be acquired
whenever an input request is made by DeepFaceLab, allowing a Non
Interactive usage. Choices can be modified, added or removed from the
`no_interact_dict.py` dictionary just modifing the file itself, and
re-running the 
```
python DeepFaceLab_Linux/DeepFaceLab/core/interact/no_interact_dict.py
```
command.
## Swap evaluation

In addition to the creation of the face-swapped video, this pipeline
also provides an evaluation method for the face substitution.
The score assigned to each face-swapped frame is the evaluation of the
outcoming quality, based on how close the destination and the source
frames are.

For each destination-image's landmark, the distance with all the
source-images' landmakrs is calculated. The evaluation score of each
pair is the sum of the distances between corresponding landmarks'
points. We compute the Euclidean distance of each destination's image
landmark point, with the corrisponding source's image landmark point.
Then we sum up the distances of each image pair (source and dest), 
resulting in the score of the swapped frame.

<span style="color:white">
<img src="https://render.githubusercontent.com/render/math?math=\sum_{i=0}^{n} euclidean_{distance}(p_{src}, p_{dst})"/>
</span>

Where `n` is the number of landmark points of a single image, and
`p_{src}` and `p_{dst}` are two corresponding landmark points.
