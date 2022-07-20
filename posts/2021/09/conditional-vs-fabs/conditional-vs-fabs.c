#include <math.h>
#include <stdio.h>

int main(void)
{
	double residuum;

	for (int i = 0; i < 1000; i++)
	{
		for (int j = 0; j < 1000; j++)
		{
			residuum = (j % 2) ? 1.0 : -1.0;

			for (int k = 0; k < 1000; k++)
			{
				//residuum = (residuum < 0) ? -residuum : residuum;
				residuum = fabs(residuum);
			}
		}
	}

	printf("%f\n", residuum);
}
