main() {
  dst_in_workspace $DST
  mkdir Deep3DFaceRecon_pytorch/custom_img
  mkdir Deep3DFaceRecon_pytorch/custom_img/detections

  echo "$DST $SRC"
  if [ "$SRC" = "stylegan" ]; then
    stylegan_execution
  elif [ "$SRC" = "tpdne" ]; then
    tpdne_execution 
  elif [ "$SRC" = "whole" ]; then
    conda activate 
    source activate deepfacelab 
    conda info -e
    rm DeepFaceLab_Linux/workspace/data_src/*
    swap_iteration_whole_dataset
  else
   conda activate 
   source activate deepfacelab 
   conda info -e
    KDEF_execution $SRC
  fi
    conda activate 
    source activate deepfacelab 
    conda info -e
  frame_evaluation
}

frame_evaluation(){
  python DeepFaceLab_Linux/DeepFaceLab/framesEvaluation.py 
}

KDEF_execution(){
  rm DeepFaceLab_Linux/workspace/data_src/*
  cp ${SRC}/* DeepFaceLab_Linux/workspace/data_src/

  f="$(basename -- $SRC)"

  swap_single_iteration $f
}

tpdne_execution(){
  conda activate
  source activate tpdne
  conda info -e

    cd ThisPersonDoesNotExistAPI
    rm *.jpeg
    python getPerson.py
    cd ..
    echo "### ThisPersonDoesNotExistAPI Face Generated ###"

    conda activate 
    source activate lme
    conda info -e

    extract_landmarks 
    echo "### Landmarks Extracted ###"

    conda activate 
    source activate deep3d_pytorch
    conda info -e

    reconstruct
    echo "### OBJ built ###"

    conda info -e
    obj_to_png
    echo "### pngs from OBJ created ###"

    conda activate 
    source activate deepfacelab 
    conda info -e

    seed=$((1 + $RANDOM % 4294967296))
    swap_single_iteration $seed
  }

  stylegan_execution(){
    conda activate
    source activate stylegan2
    conda info -e
    seed=$((1 + $RANDOM % 4294967296))
    echo "$seed"

    stylegan_generate $seed
    echo "### Stylegan Face Generated ###"

    conda activate 
    source activate lme
    conda info -e

    extract_landmarks $seed
    echo "### Landmarks Extracted ###"

    conda activate 
    source activate deep3d_pytorch
    conda info -e

    reconstruct
    echo "### OBJ built ###"

    conda info -e
    obj_to_png
    echo "### pngs from OBJ created ###"

    conda activate 
    source activate deepfacelab 
    conda info -e

    swap_single_iteration $seed
  }

  dst_in_workspace(){
    rm DeepFaceLab_Linux/workspace/data_dst.mp4
    rm DeepFaceLab_Linux/workspace/data_dst/*.*
    rm DeepFaceLab_Linux/workspace/data_dst/aligned/*
    rm DeepFaceLab_Linux/workspace/data_dst/aligned_debug/*
    cp $DST DeepFaceLab_Linux/workspace/data_dst.mp4

    conda activate 
    source activate deepfacelab 
    conda info -e

    cd DeepFaceLab_Linux/scripts
    ./3_extract_image_from_data_dst.sh                                  
    cd ../..
  } 

  src_in_workspace(){
    rm DeepFaceLab_Linux/workspace/data_src/*.*
    rm DeepFaceLab_Linux/workspace/data_src/aligned/*
    rm DeepFaceLab_Linux/workspace/data_src/aligned_debug/*
    cp $SRC/* DeepFaceLab_Linux/workspace/data_src/
  }
  swap_iteration_whole_dataset(){
    get_KDEF_folders
    while read -r line;
        do
        cp DeepFaceLab_Linux/KDEF_and_AKDEF/KDEF/${line}/* workspace/data_src
        swap_single_iteration ${line}
    done < people.txt

    cd ../..
  }

  swap_single_iteration(){
    cd DeepFaceLab_Linux/scripts
    ./4_data_src_extract_faces_S3FD.sh                        
    ./5_data_dst_extract_faces_S3FD.sh                            
    ./6_train_SAEHD_no_preview.sh                                         
    ./7_merge_SAEHD.sh                 
    ./8_merged_to_mp4.sh                                                 
    cd ..
    mkdir ../material/
    mkdir ../material/results
    cp workspace/result.mp4 ../material/results/r${1}.mp4                              
    cd ..
  }

  get_KDEF_folders(){
      ls KDEF_and_AKDEF/KDEF > people.txt
  }

  stylegan_generate(){
    cd stylegan2-ada-pytorch
    rm out/*.png
    python generate.py --outdir=out --trunc=1 --seeds=$1 --network=https://nvlabs-fi-cdn.nvidia.com/stylegan2-ada-pytorch/pretrained/metfaces.pkl
    cd ..
  }

  extract_landmarks(){
    rm landmarks.txt
    touch landmarks.txt
    if [ "$SRC" = "stylegan" ]; then
      IMG=$(ls stylegan2-ada-pytorch/out/)
      python3 lmDeep3DFR.py -img "stylegan2-ada-pytorch/out/$IMG"
    elif [ "$SRC" = "tpdne" ]; then
	    python3 lmDeep3DFR.py -img "ThisPersonDoesNotExistAPI/a_beautiful_person.jpeg"
    fi
    rm Deep3DFaceRecon_pytorch/custom_img/*.png  Deep3DFaceRecon_pytorch/custom_img/detections/*.txt
    if [ "$SRC" = "stylegan" ]; then
	    cp stylegan2-ada-pytorch/out/$IMG Deep3DFaceRecon_pytorch/custom_img/img.png
    elif [ "$SRC" = "tpdne" ]; then
	    cp ThisPersonDoesNotExistAPI/a_beautiful_person.jpeg Deep3DFaceRecon_pytorch/custom_img/img.png
    fi
	  cp landmarks.txt Deep3DFaceRecon_pytorch/custom_img/detections/img.txt
}

reconstruct(){
        rm Deep3DFaceRecon_pytorch/checkpoints/model/results/custom_img/epoch_20_000000/*
        cd Deep3DFaceRecon_pytorch
        python test.py --name=model --epoch=20 --img_folder=custom_img
        cd ..
}

obj_to_png(){
        blender -b -P TransformMeshToGIFSprite/GIFandSpriteFromModel.py -- --inm 'Deep3DFaceRecon_pytorch/checkpoints/model/results/custom_img/epoch_20_000000/img.obj'
        rm DeepFaceLab_Linux/workspace/data_src/*.png
        mv TransformMeshToGIFSprite/*.png DeepFaceLab_Linux/workspace/data_src/
}

if [ $# -le 3 ]; then
  echo "Correct usage: ./pipelineAutomation.sh -s <src_path> -d <dst_path> \n"
  exit 0
fi
while [ $# -gt 0 ]; do
  case $1 in
    -d|--data-dst)
      if [ -z $2 ]; then
        echo "Param error: destination (-d) must be specified!\n"
        echo "Correct usage: ./pipelineAutomation.sh -s <src_path> -d <dst_path> \n"
        exit 0
      fi
      DST="$2"
      shift # past argument
      shift # past value
      ;;
    -s|--src-data)
      if [ -z $2 ]; then
        echo "Param error: source (-s) must be specified!\n"
        echo "Correct usage: ./pipelineAutomation.sh -s <src_path> -d <dst_path> \n"
        exit 0
      fi
      SRC="$2"
      shift # past argument
      shift # past value
      ;;
  esac
done
main 
echo $DST $SRC 

