
import pandas as pd
import networkx as nx
import matplotlib.pyplot as plt

# Load the uploaded CSV file
file_path = '/mnt/data/giub_pubs_2010_present_kw.csv'
data = pd.read_csv(file_path)

# Count the frequency of each keyword in the entire dataset
keyword_counts = data.stack().value_counts()

# Select the top 150 most frequent keywords
top_keywords = keyword_counts.nlargest(150).index.tolist()

# Filter the rows to only include those with at least one of the top 150 keywords
filtered_data = data[data.apply(lambda row: any(kw in top_keywords for kw in row), axis=1)]

# Generate a co-occurrence matrix for the top 150 keywords
co_occurrence_matrix = pd.DataFrame(0, index=top_keywords, columns=top_keywords)

# Update the co-occurrence matrix based on the filtered data
for _, row in filtered_data.iterrows():
    keywords = [kw for kw in row if kw in top_keywords]
    for i in range(len(keywords)):
        for j in range(i + 1, len(keywords)):
            co_occurrence_matrix.loc[keywords[i], keywords[j]] += 1
            co_occurrence_matrix.loc[keywords[j], keywords[i]] += 1

# Save the edge list for Gephi
edge_list = co_occurrence_matrix.stack().reset_index()
edge_list.columns = ['Source', 'Target', 'Weight']
edge_list = edge_list[edge_list['Weight'] > 0]  # Remove edges with zero weight

gephi_file_path = '/mnt/data/gephi_edge_list.csv'
edge_list.to_csv(gephi_file_path, index=False)

# Create a graph from the edge list and save as GraphML
G = nx.from_pandas_edgelist(edge_list, 'Source', 'Target', ['Weight'])
graphml_file_path = '/mnt/data/gephi_edge_list.graphml'
nx.write_graphml(G, graphml_file_path)

# Plot the top 20 most frequent keywords
top_20_keywords = keyword_counts.nlargest(20)
plt.figure(figsize=(10, 6))
top_20_keywords.plot(kind='bar')
plt.title('Top 20 Most Frequent Keywords')
plt.ylabel('Frequency')
plt.xlabel('Keywords')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

# Plot the distribution of co-occurrence weights
plt.figure(figsize=(10, 6))
co_occurrence_weights = edge_list['Weight']
plt.hist(co_occurrence_weights, bins=50, log=True)
plt.title('Distribution of Co-occurrence Weights')
plt.ylabel('Frequency')
plt.xlabel('Co-occurrence Weight')
plt.tight_layout()
plt.show()
