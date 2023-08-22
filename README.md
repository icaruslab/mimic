# Mimic

Is a bash script that uses HTTrack to crawl and download a website then publish the generated files on IPFS network.
The script can also update previously crawled websites and download any new content.

mimic.sh is a work in progress and more features will be added in the future.

**Current features**

- Crawl and download the entire structure of a website using HTTrack
- publish the generated files to IPFS
- Log the IPFS path
- Publish the new mirror using IPNS address (optional)
- Manage and log IPNS keys (optional)

# Requirements

The script will check for HTTrack and IPFS and make sure they are installed on your system.

[How to install HTTrack](https://fightcensorship.tech/docs/static-mirroring/httrack-guide/)

[How to install IPFS](https://fightcensorship.tech/docs/alternative-publishing-methods/ipfs/ipfs/)

# Usage

This script was created for the purpose of creating and updating static mirrors for censored websites.

- Clone the repository `git clone` 

- Give the script permissions to run `chmod +x mimic.sh`

---

# Todo

- [ ] Improve error handling
- [ ] Improve logging and create a separate log file for each mirror
- [ ] Improve IPNS keys handling
- [ ] Add the ability to mirror a specific page/URL
- [ ] Restructure the script to accept arguments
- [ ] Setup automatic updates for specific mirrors using Cron
- [ ] Automatically install HTTrack and IPFS if not found
- [ ]  Amazon S3 support
- [ ] MS Windows support
  
   

---

# Disclaimer

This code is unstable and developed for specific testing purposes, it is not meant for production environments and comes with no guarantees or support.

**This script was created for the purpose of creating static mirrors for censored independent media and human rights websites.**

**It's always advisable to try and obtain permissions from the admins of any website you are trying to mirror especially that continuous crawling can cause the target server to overload and can be recognized as malicious traffic and subsequently blocked.**

**This script is not meant to be used for phishing or downloading copyrighted content and the developers are not responsible for any misuse.**