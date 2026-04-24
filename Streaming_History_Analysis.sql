select skipped, shuffle, reason_start, reason_end, 
	master_metadata_album_album_name as album, 
	master_metadata_album_artist_name as artist, 
	master_metadata_track_name as song, 
	ms_played / 60000.0 AS minutes_played, sh.offline, -- changed milliseconds to minutes
	date(ts) as date,
	time(ts) as time
from streaming_history sh 
where master_metadata_track_name != '' -- made sure no null song value was being added to the end result


--Listening Behavior
-- Which aritsts do I listen to the most?
select Round((sum(ms_played) / 60000.0),1) as minutes_played, sh.master_metadata_album_artist_name as artist_name,
		Round((sum(ms_played) / 3600000.0),1) as hours_played, count(*) as streams -- changed milliseconds to hours and rounded said value
from streaming_history sh 
where sh.master_metadata_track_name != ''
group by sh.master_metadata_album_artist_name 
Order by 1 Desc 
limit 10 -- only the top 10 most played artists will be visible

-- Which songs have the highest total listening time?
	select master_metadata_track_name as song,
		Round((sum(ms_played) / 60000.0),1) as minutes_played, 
		Round((sum(ms_played) / 3600000.0),1) as hours_played
	from streaming_history sh 
	where master_metadata_track_name != ''
	group by 1, master_metadata_album_artist_name --this is because there are songs with the same name from different arists, so songs with different arists are counted in different places
	order by 2 desc
	limit 10

-- What time of day do I listen to music most?
	Select STRFTIME('%H:00',ts) as hour_of_day, -- getting the hour from the spotify data
		   Round((sum(ms_played) / 60000.0),1) as minutes_played, --this way it counts how many minutes i have listened in this time period
			count(*) as total_streams -- this shows how many streams happened in total
	from streaming_history sh 
	where sh.master_metadata_track_name != ''
	group by 1 -- per hour of day
	order by 2 desc
	
	
--Time Analysis 
-- How has my listening activity changed over time? 
	
	--Top Artist per Month of Each Year:
	WITH monthly_artist AS (
	    SELECT 
	        STRFTIME('%Y', ts) AS year, -- getting the year from the spotify data
	        STRFTIME('%m', ts) AS month, -- getting the month from the spotify data
	        master_metadata_album_artist_name AS artist_name,
	        SUM(ms_played) AS total_played -- total listened time in milliseconds
	    FROM streaming_history
	    WHERE master_metadata_track_name != ''
	    GROUP BY year, month, artist_name
	),
	ranked AS (
	    SELECT *,
	           RANK() OVER (
	               PARTITION BY year, month -- to show each top artist by each month of each year
	               ORDER BY total_played DESC -- placing a rank based on the total listened time
	           ) AS rnk
	    FROM monthly_artist
	)
	SELECT
	    artist_name,
	    month,
	    year,
	    COUNT(*) OVER (PARTITION BY artist_name) AS times_top_of_month -- shows how many said artist ranked top of the month
	FROM ranked
	WHERE rnk = 1 -- shows only the top one artist of each month of each year
	ORDER BY year, month;
	
	--Top Artist per Year: 
	WITH monthly_artist AS ( -- same thing as above but just the top artist of each year, not of each month
	    SELECT 
	        STRFTIME('%Y', ts) AS year, 
	        master_metadata_album_artist_name AS artist_name,
	        SUM(ms_played) AS total_played
	    FROM streaming_history
	    WHERE master_metadata_track_name != ''
	    GROUP BY year, artist_name
	),
	ranked AS (
	    SELECT *,
	           RANK() OVER (
	               PARTITION BY year
	               ORDER BY total_played DESC
	           ) AS rnk
	    FROM monthly_artist
	)
	SELECT
	    artist_name,
	    year,
	    COUNT(*) OVER (PARTITION BY artist_name) AS times_top_of_month
	FROM ranked
	WHERE rnk = 1
	ORDER BY year;
		
	--Top Listening Time per Month/Year:
	select ROUND(SUM(ms_played)/60000.0,1) AS minutes_played, 
			STRFTIME('%Y', ts) AS year,
	        STRFTIME('%m', ts) AS month
	 from streaming_history sh 
	 where sh.master_metadata_track_name != ''
	 group by 2,3
	 order by 2,3
			
	--Unique Tracks per Month/Year:
	 select STRFTIME('%Y', ts) AS year, STRFTIME('%m', ts) AS month, 
	 		count(distinct sh.master_metadata_track_name || master_metadata_album_artist_name) as unique_track, 
		-- finds only songs that were streamed for the first time
	 		count(*) as total_streams 
	 from streaming_history sh 
	 where sh.master_metadata_track_name  != ''
	 group by 1,2
	 order by 1,2

-- Which day of the week do I listen the most?
	Select case strftime('%w', ts) -- getting day of the week where Sunday starts as 0 and Saturday as 6
  			when '0' then 'Sunday' -- changing each 0-6 to it's corresponding day of the week
 			when '1' then 'Monday'
 			when '2' then 'Tuesday'
  			when '3' then 'Wednesday'
  			when '4' then 'Thursday'
  			when '5' then 'Friday'
  		  else 'Saturday' end as weekday,
  		  ROUND(SUM(ms_played)/60000.0,1) AS minutes_played,
		  count(*) as total_streams
	from streaming_history sh 
	where sh.master_metadata_track_name != ''
	group by 1
	order by 2 desc
	
	
--Music Preferences
-- What albums do I replay most often?
	select sh.master_metadata_album_album_name as album,
			count(*) as total_plays, sh.master_metadata_album_artist_name, 
		-- selecting artist, in case an album's name is shared across several different artists
			ROUND(SUM(ms_played)/60000.0,1) AS minutes_played
	from streaming_history sh 
	where sh.master_metadata_album_album_name != ''
	group by 1
	order by 2 desc
	limit 10
	

	

