#!/bin/sh
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DEBIAN_FRONTEND=noninteractive sudo apt-get -y update
DEBIAN_FRONTEND=noninteractive sudo apt-get -y install ffmpeg

dir=/mnt/disks/share
infile=$dir/input/video-$BATCH_TASK_INDEX.mp4
outfile=$dir/output/video-$BATCH_TASK_INDEX.webm
vopts="-c:v libvpx-vp9 -b:v 1800k -minrate 1500 -maxrate 1610"

mkdir -p $dir/output
ffmpeg -i $infile $vopts -an $outfile
