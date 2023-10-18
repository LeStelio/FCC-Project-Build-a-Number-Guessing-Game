#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

RANDOM_NUMBER=$((1 + $RANDOM % 1000))

# ask for username
echo "Enter your username:"
read USERNAME

# check username length
if [ ${#USERNAME} -le 22 ]
then
  # check if user is in database
  CHECK_USER_RESULT=$($PSQL "SELECT username FROM users WHERE username = '$USERNAME'")
  # if not in database
  if [[ -z $CHECK_USER_RESULT ]]
  then
    # insert in database and welcome*
    INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")

    echo "Welcome, $USERNAME! It looks like this is your first time here."
  else
    # else get stats
    GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username = '$USERNAME'")
    BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username = '$USERNAME'")
    # welcome back with stats
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  fi
else
  echo -e "\nYour username exceeds the maximum allowed length."
fi

# start the game
NUMBER_OF_GUESSES=0

function GAME() {
# initial prompt and handling of future arguments
if [[ -z $1 ]]
then
  echo "Guess the secret number between 1 and 1000:"
else
  echo $1
fi

read USER_GUESS
# check if integer input
if [[ $USER_GUESS =~ ^[0-9]+$ ]]
then
  # if less than or greater than number to guess
  if [ $USER_GUESS -ne $RANDOM_NUMBER ]
  then
    if [ $USER_GUESS -lt $RANDOM_NUMBER ]
    then
        NUMBER_OF_GUESSES=$(($NUMBER_OF_GUESSES + 1))
        GAME "It's higher than that, guess again:"      
    elif [ $USER_GUESS -gt $RANDOM_NUMBER ]
    then
      NUMBER_OF_GUESSES=$(($NUMBER_OF_GUESSES + 1))
      GAME "It's lower than that, guess again:"
    fi
  else
    # if number has been guessed correctly
    NUMBER_OF_GUESSES=$(($NUMBER_OF_GUESSES + 1))
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $RANDOM_NUMBER. Nice job!"
    # if first game
    if [[ -z $GAMES_PLAYED ]]
    then
      UPDATING_GAMES_PLAYED_RESULT=$($PSQL "UPDATE users SET games_played = 1 WHERE username = '$USERNAME'")
      UPDATING_BEST_RESULT=$($PSQL "UPDATE users SET best_game = $NUMBER_OF_GUESSES WHERE username = '$USERNAME'")
    # else update the stats
    else
      UPDATING_GAMES_PLAYED_RESULT=$($PSQL "UPDATE users SET games_played = $(($GAMES_PLAYED + 1)) WHERE username = '$USERNAME'")
      # if personnal best beaten
      if [[ $NUMBER_OF_GUESSES -lt $BEST_GAME ]]
      then
        UPDATING_BEST_RESULT=$($PSQL "UPDATE users SET best_game = $NUMBER_OF_GUESSES WHERE username = '$USERNAME'")
      fi
    fi
    exit
  fi
else
  # if input not an integer
  GAME "That is not an integer, guess again:"
fi
}
GAME
