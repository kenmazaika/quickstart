class Api::TweetsController < ActionController::API
  def index
    tweets = Tweet.all
    # render json: tweets
    render json: "Yolo Swag x2"
  end

  def create
    tweet = Tweet.create(tweet_params)
    render json: tweet
  end

  def show
    tweet = Tweet.find(params[:id])
    render json: tweet
  end

  def update
    tweet = Tweet.find(params[:id])
    tweet.update(tweet_params)
    render json: tweet
  end

  def destroy
    tweet = Tweet.find(params[:id])
    tweet.destroy
    render json: {}
  end

  private

  def tweet_params
    params.require(:tweet).permit(:content, :author)
  end


end
