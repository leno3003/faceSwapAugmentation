main() {
  echo "$DST $SRC"
  mkdir Deep3DFaceRecon_pytorch/custom_img
  mkdir Deep3DFaceRecon_pytorch/custom_img/detections
  rm DeepFaceLab_Linux/workspace/data_src/*.png
  rm DeepFaceLab_Linux/workspace/data_src/*.PNG
  rm DeepFaceLab_Linux/workspace/data_src/*.jpg
  rm DeepFaceLab_Linux/workspace/data_src/*.JPG
  rm DeepFaceLab_Linux/workspace/data_src/aligned/*.png
  rm DeepFaceLab_Linux/workspace/data_src/aligned/*.PNG
  rm DeepFaceLab_Linux/workspace/data_src/aligned/*.jpg
  rm DeepFaceLab_Linux/workspace/data_src/aligned/*.JPG
  rm DeepFaceLab_Linux/workspace/data_src/aligned_debug/*.png
  rm DeepFaceLab_Linux/workspace/data_src/aligned_debug/*.PNG
  rm DeepFaceLab_Linux/workspace/data_src/aligned_debug/*.jpg
  rm DeepFaceLab_Linux/workspace/data_src/aligned_debug/*.JPG
  dst_in_workspace $DST

  seed=$((1 + $RANDOM % 4294967296))

  if [ -f $SRC ]; then
    echo "Not null"
    src_in_workspace 
    conda activate 
    source activate deepfacelab 
    conda info -e

    DeepFaceLab_exec $seed
  elif [ "$SRC" = "stylegan" ]; then
    echo "stylegan2"
    stylegan_execution
  elif [ "$SRC" = "tpdne" ]; then
    echo "tpdne"
    tpdne_execution 
  elif [ "$SRC" = "whole" ]; then
    echo "whole"
    conda activate 
    source activate deepfacelab 
    conda info -e
    swap_iteration_whole_dataset
  else
    echo "Kdef"
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

DeepFaceLab_exec(){
    cd DeepFaceLab_Linux/scripts
    ./2_extract_image_from_data_src.sh
    ./4_data_src_extract_faces_S3FD.sh                        
    ./5_data_dst_extract_faces_S3FD.sh                            
    ./6_train_SAEHD_no_preview.sh                                         
    ./7_merge_SAEHD.sh                 
    ./8_merged_to_mp4.sh                                                 
    cd ..
    mkdir ../material/
    mkdir ../material/results
    d=$( echo ${DST%/*} )
    d=$(echo ${d##*/})
    mkdir ../material/results/${d}-${seed}/
    cp workspace/result.mp4 ../material/results/${d}-${seed}/${d}-${seed}.mp4                              
    cd ..

}

src_in_workspace(){
    rm DeepFaceLab_Linux/workspace/data_src/*.*
    rm DeepFaceLab_Linux/workspace/data_src/aligned/*
    rm DeepFaceLab_Linux/workspace/data_src/aligned_debug/*

    cp $SRC DeepFaceLab_Linux/workspace/data_src.mp4
  }

frame_evaluation(){
  python DeepFaceLab_Linux/DeepFaceLab/framesEvaluation.py 
  base=$( echo ${DST%/*} )
  base=$(echo ${base##*/})
  cp dists.csv material/results/${base}-${seed}/${base}-${seed}.full.csv 
  cp distsSimple.csv material/results/${base}-${seed}/${base}-${seed}.csv
  cp rangeMax.txt material/results/${base}-${seed}/${base}-${seed}.rangeMax

}

KDEF_execution(){
  rm DeepFaceLab_Linux/workspace/data_src/*
  cp ${SRC}/* DeepFaceLab_Linux/workspace/data_src/

  f="$(basename -- $SRC)"

  from="KDEF"
  swap_single_iteration $f $from
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

    from="tpdne"
    swap_single_iteration $seed $from
  }

  stylegan_execution(){
    conda activate
    source activate stylegan2
    conda info -e
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

    from="stylegan2"
    swap_single_iteration $seed $from
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

  swap_iteration_whole_dataset(){
    get_KDEF_folders
    while read -r line;
        do
        cp DeepFaceLab_Linux/KDEF_and_AKDEF/KDEF/${line}/* workspace/data_src
        from="KDEF"
        swap_single_iteration ${line} ${from}
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

    d=$( echo ${DST%/*} )
    d=$(echo ${d##*/})

    mkdir ../material/results/${d}-${seed}/
    cp workspace/result.mp4 ../material/results/${d}-${seed}/${d}-${seed}.mp4                              
    cp ../Deep3DFaceRecon_pytorch/custom_img/img.png ../material/results/${d}-${seed}/src.png
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
        blender -b -P objToPngs/GIFandSpriteFromModel.py -- --inm 'Deep3DFaceRecon_pytorch/checkpoints/model/results/custom_img/epoch_20_000000/img.obj'
        mv objToPngs/*.png DeepFaceLab_Linux/workspace/data_src/
}

if [ $# -le 3 ]; then
        echo "Correct usage: ./pipelineAutomation.sh -s <src_path> (or -sv <path_to_video>) -d <dst_path> \n"
  exit 0
fi
while [ $# -gt 0 ]; do
  case $1 in
    -d|--data-dst)
      if [ -z $2 ]; then
        echo "Param error: destination (-d) must be specified!\n"
        echo "Correct usage: ./pipelineAutomation.sh -s <src_path> (or -sv <path_to_video>) -d <dst_path> \n"
        exit 0
      fi
      DST="$2"
      shift # past argument
      shift # past value
      ;;
    -s|--src-data)
      if [ -z $2 ]; then
        echo "Param error: source (-s) must be specified!\n"
        echo "Correct usage: ./pipelineAutomation.sh -s <src_path> (or -sv <path_to_video>) -d <dst_path> \n"
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

