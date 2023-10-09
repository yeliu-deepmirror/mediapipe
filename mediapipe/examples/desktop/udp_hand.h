// Copyright 2023 DeepMirror Inc. All rights reserved.

#ifndef MAP_OUTSIDEIN_UDP_POSE_H_
#define MAP_OUTSIDEIN_UDP_POSE_H_

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <deque>
#include <iomanip>
#include <mutex>
#include "mediapipe/framework/formats/classification.pb.h"
#include "mediapipe/framework/formats/landmark.pb.h"

namespace dm {

class UdpHandServer {
 public:
  explicit UdpHandServer(const std::string& address_ip, int port) {
    // CHECK(!address_ip.empty());
    sockfd_ = socket(AF_INET, SOCK_DGRAM, 0);
    // CHECK(sockfd_ >= 0);
    memset(&server_addr_, 0, sizeof(server_addr_));
    server_addr_.sin_family = AF_INET;
    server_addr_.sin_port = htons(port);
    server_addr_.sin_addr.s_addr = inet_addr(address_ip.c_str());
  }
  ~UdpHandServer() { close(sockfd_); }

  void UdpPublishHand(int64_t timestamp, const std::vector<mediapipe::NormalizedLandmarkList>& landmarks,
                      const std::vector<mediapipe::ClassificationList>& handnesses) {
    std::unique_lock<std::mutex> ul(proc_mutex_);

    std::stringstream ss_output;
    ss_output << std::fixed << std::setprecision(5);
    ss_output << timestamp << ",";
    ss_output << landmarks.size() << ",";
    for (size_t i = 0; i < landmarks.size(); i++) {
      // write the handness
      for (const auto& classification : handnesses[i].classification()) {
        ss_output << classification.score() << "," << classification.label() << ",";
      }
      // write the landmarks
      for (const auto& landmark : landmarks[i].landmark()) {
        ss_output << landmark.x() << "," << landmark.y() << "," << landmark.z() << ",";
      }
    }
    ss_output << frame_cnt_ << "\n";
    // add current time at the end
    frame_cnt_++;
    int cnt = sendto(sockfd_, ss_output.str().c_str(), ss_output.str().length(), MSG_CONFIRM,
                     (const struct sockaddr*)&server_addr_, sizeof(server_addr_));
  }

 private:
  int sockfd_;
  int64_t frame_cnt_ = 0;
  std::mutex proc_mutex_;
  struct sockaddr_in server_addr_;
};

}  // namespace dm

#endif  // MAP_OUTSIDEIN_UDP_POSE_H_
