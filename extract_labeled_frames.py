#!/usr/bin/env python

import pandas as pd
import os
import cv2
import numpy as np
import argparse


# ==============================================================================

ACTION_NAME_C15 = [
    'Baseline', 'TextingRight', 'TalkCellRight', 'TextingLeft', 'TalkCellLeft', 
    'OperateRadio', 'Drink', 'LookBehind', 'HairAndMakeup', 'TalkPassengerRight', 
    'TalkPassengerLeft', 'LookBelow', 'LookRight', 'LookLeft', 'Yawn'
]

SWAP = {'LookRight':'LookLeft', 
        'TalkCellRight':'TalkCellLeft', 
        'TalkPassengerRight':'TalkPassengerLeft', 
        'TextingRight':'TextingLeft'}


def main():

    argparser = argparse.ArgumentParser(
        description=__doc__)

    argparser.add_argument(
        '-f', '--recorder-filename',
        metavar='F',
        default="test1.csv",
        help='recorder filename (test1.csv)')
    argparser.add_argument(
        '-x', '--extended-filename',
        metavar='X',
        default=None,
        help='extended csv filename (test1.csv/mp4)')
    argparser.add_argument(
        '-o', '--output-directory',
        metavar='F',
        default=None,
        help='output directory')
    argparser.add_argument(
        '-u', '--uid',
        metavar='F',
        default=None,
        type=int,
        help='user id')

    # argparser.add_argument(
    #     '-o', '--output-filename',
    #     metavar='F',
    #     default=None,
    #     help='output filename')
    argparser.add_argument(
        '-s', '--skip-time',
        default=2.0,
        type=float,
        help='Skipped time in each driver action interval (default: 2.0)')
    argparser.add_argument(
        '-n', '--num-frames',
        default=2,
        type=int,
        help='Frames extracted in each driver action interval.')

    args = argparser.parse_args()

    try:
        if args.output_directory is None or not os.path.isdir(args.output_directory):
            print('Missing output directory')
            exit()
        if args.uid is None:
            print('Missing user id')
            exit()

        abs_recorder_filename = os.path.abspath(args.recorder_filename)
        abs_recorder_basename, rec_fname = os.path.split(abs_recorder_filename)
        base_fname = os.path.splitext(rec_fname)[0]

        csvrec_fname = os.path.join(abs_recorder_basename, base_fname + '.csv')
        video_fname = os.path.join(abs_recorder_basename, base_fname.replace('recording_', 'capture-') + '.avi')
        csvvid_fname = os.path.join(abs_recorder_basename, base_fname.replace('recording_', 'capture-') + '.csv')

        base_extname = None
        csvext_fname = None
        if args.extended_filename is not None:
            abs_extended_filename = os.path.abspath(args.extended_filename)
            abs_extended_basename, ext_fname = os.path.split(abs_extended_filename)
            base_extname = os.path.splitext(ext_fname)[0]
            video_fname = os.path.join(abs_extended_basename, base_extname + '.mp4')
            csvext_fname = os.path.join(abs_extended_basename, base_extname + '.csv')
            assert os.path.exists(csvext_fname)

        # print('csvrec_fname:', csvrec_fname)
        # print('video_fname:', video_fname)
        # print('csvvid_fname:', csvvid_fname)
        # print('csvext_fname:', csvext_fname)
        assert os.path.exists(csvrec_fname) and os.path.exists(video_fname)

        rnd_state = np.random.RandomState(seed=1234)

        # Load the recording CSV
        csv = pd.read_csv(csvrec_fname)
        csv = csv[['time', 'hud_driver_action_popup']]

        # Load the video keyframe map
        kfm = pd.read_csv(csvvid_fname)
        kfm.simulation_time = kfm.simulation_time - kfm.simulation_time.iloc[0]

        # align the closest keyframe time to the corresponding simulation time
        indices = np.searchsorted(kfm.simulation_time, csv.time)
        indices[indices == len(kfm)] = len(kfm) - 1

        # load face validity (only frames with valid_face=True will be extractes)
        if csvext_fname is not None:
            csvext = pd.read_csv(csvext_fname)
            print(len(csv), len(csvext), len(kfm))
            assert len(csvext) == len(kfm)
            valid_face = np.array(csvext.valid_face)
        else:
            valid_face = np.array([True] * len(kfm))

        # print(csv.head())
        # print(kfm.head())
        # print(valid_face)
        # print(indices)

        csv['merge_time'] = np.array(kfm.simulation_time)[indices]
        csv['merge_frame'] = np.array(kfm.frame_counter)[indices]
        csv['valid_face'] = valid_face[indices]
        # print(csv.head())
        # exit(0)

        # Open the video stream using OpenCV
        capture = cv2.VideoCapture(video_fname)

        # Mark each unique action group
        grp_start = csv.hud_driver_action_popup != csv.hud_driver_action_popup.shift(1)
        csv['grp_id'] = grp_start.cumsum()
        # Iterate over the named groups of driver actions (NaN are already dropped)
        action_groups = csv.groupby(['hud_driver_action_popup', 'grp_id'])
        # Keep only the last performed action
        action_dfs = {}
        for (name, gid), df_group in action_groups:
            action_dfs[name] = df_group
            #print('##', name, gid, df_group.time.min(), df_group.time.max())

        for name in action_dfs:
            df = action_dfs[name]
            start, end = df.time.min() + args.skip_time, df.time.max() - args.skip_time
            df = df[(start <= df.time) & (df.time <= end) & df.valid_face]
            print(name, len(action_dfs[name]), len(df))
            # keep only the first row of each unique video frame number
            df = df.groupby('merge_frame').head(1)
            #print(df)
            if len(df) == 0:
                continue
            #print(name, start, end)
            sample_frames = df.sample(n=args.num_frames, replace=False, random_state=rnd_state)

            count = 0
            for ii, row in sample_frames.iterrows():
                capture.set(cv2.CAP_PROP_POS_FRAMES, row.merge_frame)
                ret, frame = capture.read()
                # out_fname = os.path.join(args.output_directory, 'frame_%s_%d.png' % (name, count))
                # print('Frame %-5d %s  -> %s '%(row.merge_frame, name, out_fname))

                out_actname = name
                action_id = ACTION_NAME_C15.index(out_actname)
                out_act_dir = os.path.join(args.output_directory, 'C%02d' % action_id)
                out_fname = os.path.join(out_act_dir, 'user%02d-f%02d.png' % (args.uid, count))
                os.makedirs(out_act_dir, exist_ok=True)
                print('Frame %-5d %s  -> %s '%(row.merge_frame, out_actname, out_fname))
                cv2.imwrite(out_fname, frame)
                if name in SWAP:
                    frame = frame[:, ::-1] # flip horizontally
                    out_actname = SWAP[name]
                    action_id = ACTION_NAME_C15.index(out_actname)
                    out_act_dir = os.path.join(args.output_directory, 'C%02d' % action_id)
                    out_fname = os.path.join(out_act_dir, 'user%02d-f%02d.png' % (args.uid, count))
                    os.makedirs(out_act_dir, exist_ok=True)
                    print('Frame %-5d %s  -> %s '%(row.merge_frame, out_actname, out_fname))
                    cv2.imwrite(out_fname, frame)

                count += 1

    except KeyboardInterrupt:
        print('Frame extraction interrupted.')



if __name__ == '__main__':
    main()

