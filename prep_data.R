# Load necessary libraries
library(dplyr)
library(tidyr)
library(stringr)
library(httr)
library(jsonlite)

# Read the CSV file
file_path <- "pub_giub_2000_2024.csv"
data <- read.csv(file_path, stringsAsFactors = FALSE)

data <- data[data$year>=2010,]

## Set up Open AI Connection --------------------------------------------------

my_API <- "sk-proj-yyxxx"
# Asking Questions to ChatGPT, Saving and Cleaning Answer
hey_chatGPT <- function(answer_my_question) {
  chat_GPT_answer <- POST(
    url = "https://api.openai.com/v1/chat/completions",
    add_headers(Authorization = paste("Bearer", my_API)),
    content_type("application/json"),
    encode = "json",
    body = toJSON(list(
      model = "gpt-3.5-turbo",
      messages = list(
        list(
          role = "user",
          content = answer_my_question
        )
      )
    ), auto_unbox = TRUE)
  )
  
  response_content <- content(chat_GPT_answer, as = "parsed", type = "application/json")
  
  # Print the entire response for debugging
  # print(response_content)
  
  str_trim(response_content$choices[[1]]$message$content)
}


### Define Keywords -----------------------------------------------------------

data$keywords <- rep(NA,nrow(data))
for(i in 1:dim(data)[1]){
  
  if(!is.na(data$abstract[i])){
    prompt_p1 <- "summarize this abstract in 5 keywords (no keywords consisting of two words, also no slashes or hyphen, only one word), each separated by a comma (Make everything lower case). The keywords can only be nouns, no adjectives.  \n"
    prompt <- paste(prompt_p1,data$abstract[i])
    response <- hey_chatGPT(prompt)
    
  } else {
    prompt_p1 <- "summarize this title in 5 keywords (no keywords consisting of two words, , also no slashes or hyphen, only one word), each separated by a comma (Make everything lower case). The keywords can only be nouns, no adjectives.\n"
    prompt <- paste(prompt_p1,data$title[i])
    response <- hey_chatGPT(prompt)
    
  }
  data$keywords[i] <- response
  print(i)
}

# rm whitespace 
data$keywords <- gsub(pattern = " ", replacement = "", x = data$keywords)



### Prepare, improve and save keywords dataframe -------------------------------

# Function to split keywords into separate columns
split_keywords <- function(df, colname) {
  # Split the keywords into separate columns
  split_df <- df %>%
    separate(col = all_of(colname), into = paste0("keyword", 1:5), sep = ",", convert = TRUE)
  
  return(split_df)
}

table_keywords <- data %>% select(keywords)
# Apply the function to the sample data frame
split_keywords_df <- split_keywords(table_keywords, "keywords")
# drop rows with NA values 
split_keywords_df <- split_keywords_df %>% drop_na()
dim(split_keywords_df)

## remove all whitespace again 
split_keywords_df <- split_keywords_df %>%
  mutate_all(~ str_trim(.))

# rm everything thats not letters
split_keywords_df <- split_keywords_df %>%
  mutate_all(~ gsub("[^a-zA-Z]", "", .))





# write file
write.csv(split_keywords_df, file="giub_pubs_2010_present_kw.csv", row.names = F)




