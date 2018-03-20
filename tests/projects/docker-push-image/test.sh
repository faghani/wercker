#!/bin/bash

# This is intended to be called from wercker/test-all.sh, which sets the required environment variables
# if you run this file directly, you need to set $wercker, $workingDir and $testDir
# as a convenience, if these are not set then assume we're running from the local directory 
if [ -z ${wercker} ]; then wercker=$PWD/../../../wercker; fi
if [ -z ${workingDir} ]; then workingDir=$PWD/../../../.werckertests; mkdir -p "$workingDir"; fi
if [ -z ${testsDir} ]; then testsDir=$PWD/..; fi

testDockerPushImage () {
  testName=docker-push-image
  testDir=$testsDir/docker-push-image
  printf "testing %s... " "$testName"
  # this test uses docker-build to create an image with the following repo and tag - should match the corresponding repo and tag in wercker.yml
  repo1=myrepo1
  tag1=docker-push-image-tag1 
  # it then uses docker-push to set the image to the following repo and tag - should match the corresponding repo and tag in wercker.yml
  repo2=myrepo2
  tag2=docker-push-image-tag2
  # delete any existing image with tag $tag1 built by a previous run
  docker images | grep $tag1 | awk '{print $3}' | xargs -n1 docker rmi -f > /dev/null 2>&1
  # delete any existing image with tag $tag2 built by a previous run
  docker images | grep $tag2 | awk '{print $3}' | xargs -n1 docker rmi -f > /dev/null 2>&1
  # check no existing image with the tag $tag1 (column 2 is the tag)
  docker images | awk '{print $2}' | grep -q "$tag1"
  if [ $? -eq 0 ]; then
    echo "An image with tag $tag1 already exists"
    return 1
  fi
  # check no existing image with the repo $repo1 (column 1 is the repo)
  docker images | awk '{print $1}' | grep -q "$repo1"
  if [ $? -eq 0 ]; then
    echo "An image with repository $repo1 already exists"
    return 1
  fi  
  # check no existing image with the tag $tag2 (column 2 is the tag)
  docker images | awk '{print $2}' | grep -q "$tag2"
  if [ $? -eq 0 ]; then
    echo "An image with tag $tag2 already exists"
    return 1
  fi 
  # check no existing image with the repo $repo2 (column 1 is the repo)
  docker images | awk '{print $1}' | grep -q "$repo2"
  if [ $? -eq 0 ]; then
    echo "An image with repository $repo2 already exists"
    return 1
  fi    
  # now run the build pipeline - this creates an image both tags
  $wercker build "$testDir" --docker-local --working-dir "$workingDir" &> "${workingDir}/${testName}.log"
  #$wercker build "$testDir"  --working-dir "$workingDir" &> "${workingDir}/${testName}.log"
  if [ $? -ne 0 ]; then
    printf "failed\n"
    if [ "${workingDir}/${testName}.log" ]; then
      cat "${workingDir}/${testName}.log"
    fi
    return 1
  fi
  # verify that an image was created with the tag $tag1 (column 2 is the tag)
  docker images | awk '{print $2}' | grep -q "$tag1"
  if [ $? -ne 0 ]; then
    echo "An image with tag $tag1 was not found"
    return 1
  fi
  # verify that an image was created with the repo $repo1 (this should be the same image) (column 1 is the repo)
  docker images | awk '{print $1}' | grep -q "$repo1"
  if [ $? -ne 0 ]; then
    docker images
    echo "An image with repository $repo1 was not found"
    return 1
  fi 
  # verify that an image was created with the tag $tag2 (this should be the same image) (column 2 is the tag)
  docker images | awk '{print $2}' | grep -q "$tag2"
  if [ $? -ne 0 ]; then
    echo "An image with tag $tag2 was not found"
    return 1
  fi
  # verify that an image was created with the repo $repo2 (this should be the same image) (column 1 is the repo)
  docker images | awk '{print $1}' | grep -q "$repo2"
  if [ $? -ne 0 ]; then
    echo "An image with repository $repo2 was not found"
    return 1
  fi 

  # delete the image with tag $tag1 we've just created - the deleted image should also have the tag $tag2
  docker images | grep $tag1 | awk '{print $3}' | xargs -n1 docker rmi -f >> "${workingDir}/${testName}.log" 2>&1

  # check no existing image with the tag $tag1 (column 2 is the tag)
  docker images | awk '{print $2}' | grep -q "$tag1"
  if [ $? -eq 0 ]; then
    echo "An image with tag $tag1 already exists"
    return 1
  fi
  # check no existing image with the repo $repo1 (column 1 is the repo)
  docker images | awk '{print $1}' | grep -q "$repo1"
  if [ $? -eq 0 ]; then
    echo "An image with repository $repo1 already exists"
    return 1
  fi  
  # check no existing image with the tag $tag2 (column 2 is the tag)
  docker images | awk '{print $2}' | grep -q "$tag2"
  if [ $? -eq 0 ]; then
    echo "An image with tag $tag2 already exists"
    return 1
  fi 
  # check no existing image with the repo $repo2 (column 1 is the repo)
  docker images | awk '{print $1}' | grep -q "$repo2"
  if [ $? -eq 0 ]; then
    echo "An image with repository $repo2 already exists"
    return 1
  fi  

  # test passed
  #cat "${workingDir}/${testName}.log"
  #echo $curlOutput
  printf "passed\n"
  return 0
}

testDockerPushImageAll () {
  testDockerPushImage || return 1 
}

testDockerPushImageAll
