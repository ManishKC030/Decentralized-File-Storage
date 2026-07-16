import { FileUploaded } from "../generated/FileStorageNFT/FileStorageNFT";
import { File } from "../generated/schema";

export function handleFileUploaded(event: FileUploaded): void {
  let entity = new File(event.params.tokenId.toString());
  entity.tokenId = event.params.tokenId;
  entity.uploader = event.params.uploader;
  entity.cid = event.params.cid;
  entity.fileName = event.params.fileName;
  entity.timestamp = event.block.timestamp;
  entity.save();
}
