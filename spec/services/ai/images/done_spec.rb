require 'rails_helper'

RSpec.describe Ai::Images::Done, type: :service do
  # Note: Before running these tests for the first time, you need to:
  # 1. Make sure the webmock gem is installed
  # 2. Record the VCR cassettes by running the tests with real API calls

  let(:params) { { "type"=>"image_generation.complete", "object"=>"generation", "timestamp"=>1742379925356, "api_version"=>"v1", "data"=>{ "object"=>{ "id"=>"acf661f4-9459-4d1d-9f1f-3e23e098adb4", "createdAt"=>"2025-03-19T10:25:20.526Z", "updatedAt"=>"2025-03-19T10:25:25.277Z", "userId"=>"0bbda45c-c0db-4fad-b816-2d75455d4d75", "public"=>false, "flagged"=>false, "nsfw"=>true, "status"=>"COMPLETE", "coreModel"=>"SD", "guidanceScale"=>7, "imageHeight"=>512, "imageWidth"=>512, "inferenceSteps"=>15, "initGeneratedImageId"=>nil, "initImageId"=>nil, "initStrength"=>nil, "initType"=>nil, "initUpscaledImageId"=>nil, "modelId"=>"2067ae52-33fd-4a82-bb92-c2c55e7d2786", "negativePrompt"=>"", "prompt"=>"A Christmas bitcoin themed bill add text public address and private key", "quantity"=>1, "sdVersion"=>"SDXL_0_9", "tiling"=>false, "imageAspectRatio"=>nil, "tokenCost"=>"[FILTERED]", "negativeStylePrompt"=>"", "seed"=>"4719932205", "scheduler"=>"EULER_DISCRETE", "presetStyle"=>"ILLUSTRATION", "promptMagic"=>false, "canvasInitImageId"=>nil, "canvasMaskImageId"=>nil, "canvasRequest"=>false, "api"=>true, "poseImage2Image"=>false, "imagePromptStrength"=>nil, "category"=>nil, "poseImage2ImageType"=>nil, "highContrast"=>false, "apiDollarCost"=>"9", "poseImage2ImageWeight"=>nil, "alchemy"=>nil, "contrastRatio"=>nil, "highResolution"=>nil, "expandedDomain"=>nil, "promptMagicVersion"=>nil, "unzoom"=>nil, "unzoomAmount"=>nil, "photoReal"=>false, "promptMagicStrength"=>nil, "photoRealStrength"=>nil, "imageToImage"=>false, "controlnetsUsed"=>false, "motionLora"=>nil, "motionLoraAlpha"=>nil, "motionFrameInterpolation"=>nil, "motionNumInterpolations"=>nil, "motionDurationSeconds"=>nil, "motionModule"=>nil, "motionOfficialModelId"=>nil, "motion"=>nil, "fantasyAvatar"=>nil, "liveCanvas"=>nil, "isStoryboard"=>false, "liveGen"=>nil, "photoRealVersion"=>nil, "imageToVideo"=>nil, "motionModel"=>nil, "motionStrength"=>nil, "universalUpscaler"=>nil, "teamId"=>nil, "styleUUID"=>nil, "ultra"=>nil, "source"=>"LEONARDO", "transparency"=>"disabled", "generation_notes"=>[], "model"=>{ "id"=>"2067ae52-33fd-4a82-bb92-c2c55e7d2786", "createdAt"=>"2023-10-13T04:21:51.465Z", "updatedAt"=>"2023-10-13T04:21:51.465Z", "name"=>"AlbedoBase XL", "description"=>"A great generalist model that tends towards more CG artistic outputs. By albedobond.", "public"=>true, "userId"=>"384ab5c8-55d8-47a1-be22-6a274913c324", "flagged"=>false, "nsfw"=>false, "official"=>true, "status"=>"COMPLETE", "classPrompt"=>nil, "coreModel"=>"SD", "initDatasetId"=>nil, "instancePrompt"=>"", "sdVersion"=>"SDXL_0_9", "trainingEpoch"=>nil, "trainingSteps"=>nil, "tokenCost"=>"[FILTERED]", "batchSize"=>nil, "learningRate"=>nil, "type"=>"GENERAL", "modelHeight"=>768, "modelWidth"=>1024, "leonardoInstancePrompt"=>nil, "trainingStrength"=>"MEDIUM", "featured"=>true, "featuredImageId"=>"2590401b-a844-4b79-b0fa-8c44bb54eda0", "featuredPosition"=>3, "api"=>false, "favouriteCount"=>0, "imageCount"=>0, "enhancedModeration"=>false, "apiDollarCost"=>nil, "modelLRN"=>nil, "motion"=>nil, "teamId"=>nil }, "images"=>[ { "id"=>"2a84ad62-6f47-4572-8561-3df5264f79f2", "createdAt"=>"2025-03-19T10:25:25.280Z", "updatedAt"=>"2025-03-19T10:25:25.280Z", "userId"=>"0bbda45c-c0db-4fad-b816-2d75455d4d75", "url"=>"https://cdn.leonardo.ai/users/0bbda45c-c0db-4fad-b816-2d75455d4d75/generations/acf661f4-9459-4d1d-9f1f-3e23e098adb4/AlbedoBase_XL_a_christmas_bill_1_A_Christmas_bitcoin_themed_bi_0.jpg", "generationId"=>"acf661f4-9459-4d1d-9f1f-3e23e098adb4", "nobgId"=>nil, "nsfw"=>true, "likeCount"=>0, "trendingScore"=>0, "public"=>false, "motionGIFURL"=>nil, "motionMP4URL"=>nil, "teamId"=>nil, "image_height"=>512, "image_width"=>512 } ], "teams"=>nil } }, "image"=>{ "type"=>"image_generation.complete" } } }
  subject { described_class.call(params) }

  describe '#call' do
    before do
      ai_images(:christmas_bill).update(external_id: "acf661f4-9459-4d1d-9f1f-3e23e098adb4")
    end

    it 'updates the image status to completed' do
      expect { subject }.to change(ai_images(:christmas_bill), :status).to('completed')
    end

    it 'stores the image urls' do
      expect {
        subject
      }.to change { ai_images(:christmas_bill).reload.response_image_urls }.to([ "https://cdn.leonardo.ai/users/0bbda45c-c0db-4fad-b816-2d75455d4d75/generations/acf661f4-9459-4d1d-9f1f-3e23e098adb4/AlbedoBase_XL_a_christmas_bill_1_A_Christmas_bitcoin_themed_bi_0.jpg" ])
    end

    it 'attaches the images to the image', :vcr do
      expect { subject }.to change { ai_images(:christmas_bill).reload.images.count }.by(1)
    end
  end
end
